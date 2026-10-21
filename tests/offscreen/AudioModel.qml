import QtQuick
import "Model.js" as Model

// Offscreen stand-in for AudioModel.qml (tests/preview.sh copies it over the
// real one in a throwaway plugin copy) with the same public surface. It
// never imports Quickshell.Services.Pipewire, so previews cannot read or
// change the machine's real outputs; tests/Preview.qml sets the sample state.
QtObject {
  id: root

  property bool optionsActive: false
  // Sample nodes shaped like bound PwNodes: PipeWire-style properties and
  // channel names, so the output list classifies them as it would real ones.
  property var sinks: [
    { id: 41, name: "alsa_output.usb-sample_studio.analog-stereo", description: "Studio Headphones", ready: true,
      properties: { "device.api": "alsa", "device.bus": "usb", "device.form-factor": "headphone" }, channels: ["FrontLeft", "FrontRight"] },
    { id: 42, name: "alsa_output.pci-sample_desk.analog-stereo", description: "Desk Speakers", ready: true,
      properties: { "device.api": "alsa", "device.bus": "pci", "device.form-factor": "speaker" }, channels: ["FrontLeft", "FrontRight"] },
    { id: 43, name: "alsa_output.usb-sample_conference.mono-fallback", description: "Conference Speakerphone", ready: true,
      properties: { "device.api": "alsa", "device.bus": "usb", "device.form-factor": "speakerphone" }, channels: ["Mono"] }
  ]
  property int sinkIndex: 0
  property bool available: true
  property bool stereoSupported: true
  property bool mono: false
  property real left: 1
  property real right: 1
  property real volume: Math.max(left, right)
  property bool muted: false
  property bool channelsLocked: false
  property string error: ""

  readonly property real balance: Model.balance(left, right)
  readonly property var sink: sinkIndex >= 0 && sinkIndex < sinks.length ? sinks[sinkIndex] : null
  readonly property string sinkId: sink ? String(sink.id) : ""
  readonly property string sinkLabel: Model.sinkLabel(sink)
  readonly property var sinkEntries: sinks.map(function(node, i) {
    return Model.sinkEntry(node, Model.nodeProps(node), node.channels || [], i === sinkIndex)
  })

  function setLeft(value) { left = Model.clampVolume(value); if (channelsLocked) right = left }
  function setRight(value) { right = Model.clampVolume(value); if (channelsLocked) left = right }
  function setVolume(value) { volume = Model.clampVolume(value) }
  function setBalance(value) {
    var pair = Model.applyBalance(left, right, value)
    left = pair.left
    right = pair.right
  }
  function shiftBalance(delta) { setBalance(balance + delta) }
  function adjustBoth(delta) { setLeft(left + delta); setRight(right + delta) }
  function toggleLock() { channelsLocked = !channelsLocked }
  function toggleMute() { muted = !muted }
  function reset() { channelsLocked = false; left = 1; right = 1 }
  function selectSinkId(id) {
    for (var i = 0; i < sinks.length; i++) if (String(sinks[i].id) === String(id)) sinkIndex = i
  }
  function cycleSink(delta) { sinkIndex = (sinkIndex + delta + sinks.length) % sinks.length }
}
