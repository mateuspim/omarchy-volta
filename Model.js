.pragma library

var MAX_VOLUME = 1.5
var MAX_SINK_LABEL_LENGTH = 160

function clamp(value, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number)) number = minimum
  return Math.max(minimum, Math.min(maximum, number))
}

function clampVolume(value) { return clamp(value, 0, MAX_VOLUME) }

function percent(value) { return Math.round(clampVolume(value) * 100) + "%" }

function channelName(channel) {
  var name = String(channel === undefined || channel === null ? "" : channel)
  var dot = name.lastIndexOf(".")
  return (dot >= 0 ? name.slice(dot + 1) : name).toLowerCase().replace(/[^a-z]/g, "")
}

function parseSinkAvailability(raw) {
  var result = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var parts = lines[i].trim().split("\t")
    if (parts.length >= 2 && parts[0]) result[parts[0]] = parts[1] !== "0"
  }
  return result
}

function stereoIndices(channels) {
  var result = { left: -1, right: -1, mono: -1 }
  for (var i = 0; i < (channels || []).length; i++) {
    var name = channelName(channels[i])
    if (name === "frontleft" || name === "fl") result.left = i
    else if (name === "frontright" || name === "fr") result.right = i
    else if (name === "mono" || name === "frontcenter") result.mono = i
  }
  return result
}

function readStereo(channels, volumes) {
  var indexes = stereoIndices(channels)
  var values = volumes || []
  if (indexes.left >= 0 && indexes.right >= 0)
    return { supported: true, mono: false, left: clampVolume(values[indexes.left]), right: clampVolume(values[indexes.right]), leftIndex: indexes.left, rightIndex: indexes.right }
  if (indexes.mono >= 0)
    return { supported: false, mono: true, left: clampVolume(values[indexes.mono]), right: clampVolume(values[indexes.mono]), leftIndex: indexes.mono, rightIndex: indexes.mono }
  return { supported: false, mono: false, left: 0, right: 0, leftIndex: -1, rightIndex: -1 }
}

function withStereoVolumes(volumes, leftIndex, rightIndex, left, right) {
  var result = (volumes || []).slice()
  if (leftIndex >= 0 && leftIndex < result.length) result[leftIndex] = clampVolume(left)
  if (rightIndex >= 0 && rightIndex < result.length) result[rightIndex] = clampVolume(right)
  return result
}

// Balance is the normalized L/R difference. Preserve the louder channel and
// attenuate the opposite one, matching conventional balance controls.
function balance(left, right) {
  var maximum = Math.max(clampVolume(left), clampVolume(right))
  return maximum <= 0 ? 0 : clamp((right - left) / maximum, -1, 1)
}

function applyBalance(left, right, value) {
  var peak = Math.max(clampVolume(left), clampVolume(right))
  if (peak <= 0) return { left: 0, right: 0 }
  var b = clamp(value, -1, 1)
  return b < 0 ? { left: peak, right: peak * (1 + b) }
               : { left: peak * (1 - b), right: peak }
}

function balanceLabel(value) {
  var b = clamp(value, -1, 1)
  if (Math.abs(b) < 0.005) return "Center"
  return Math.round(Math.abs(b) * 100) + "% " + (b < 0 ? "left" : "right")
}

// PipeWire metadata is controlled by local clients and attached devices. The
// shared Omarchy dropdown and bar tooltip use Text.AutoText, so escape markup
// before labels reach QML and keep persistent-shell text reasonably bounded.
function safeSinkText(value) {
  var text = String(value === undefined || value === null ? "" : value)
    .slice(0, MAX_SINK_LABEL_LENGTH)
  return text
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .slice(0, MAX_SINK_LABEL_LENGTH)
}

function sinkLabel(node) {
  if (!node) return "No output"
  return safeSinkText(node.description || node.nickname || node.name || "Output")
}

// Scale the popup draws on: 0–100 % is the normal range and 100–150 % is the
// over-gain zone (ADR 4), so the zone always starts two thirds along a track.
var UNITY_FRACTION = 1 / MAX_VOLUME

function isOverGain(value) { return clampVolume(value) > 1.0005 }

// Track fractions for a two-tone volume fill: the part up to 100 % and the
// over-gain part beyond it. gainSplit(1.2) -> { normal: 0.667, over: 0.133 }
function gainSplit(value) {
  var volume = clampVolume(value)
  return { normal: Math.min(volume, 1) / MAX_VOLUME, over: Math.max(0, volume - 1) / MAX_VOLUME }
}

// Where the balance fill sits on a 0..1 track: it grows out of the centre
// detent toward the louder side. balanceSpan(-0.5) -> { from: 0.25, to: 0.5 }
function balanceSpan(value) {
  var b = clamp(value, -1, 1)
  return b < 0 ? { from: 0.5 + b / 2, to: 0.5 } : { from: 0.5, to: 0.5 + b / 2 }
}

// One segment of the mirrored stage meter, counted outward from the centre in
// 10 % steps. Segments past the tenth sit in the over-gain zone.
// meterSegment(11, 1.18) -> "over"; meterSegment(13, 1.18) -> "zone"
function meterSegment(index, value) {
  var lit = Math.round(clampVolume(value) * 10) > index
  var inZone = index >= 10
  if (lit) return inZone ? "over" : "lit"
  return inZone ? "zone" : "off"
}

function heroMeta(available, mono, position, count) {
  if (!available) return "No output available"
  var mode = mono ? "Mono" : "Stereo"
  return count > 1 ? mode + " · output " + position + " of " + count : mode + " output"
}

function heroDetail(muted, linked, balanceValue, stereo) {
  if (muted) return "Muted"
  if (linked) return "Linked"
  return stereo ? balanceLabel(balanceValue) : ""
}

// Footer key hints. Per-row keys sit beside their own rows; these are the
// actions without a row of their own plus the ones worth repeating.
function footerHints(stereo) {
  var hints = [{ keys: ["Tab"], label: "output" }]
  if (stereo) hints.push({ keys: ["⇧L"], label: "link" })
  hints.push({ keys: ["M"], label: "mute" }, { keys: ["R"], label: "reset" }, { keys: ["Q"], label: "close" })
  return hints
}
