import QtQuick
import "Model.js" as Model

// Offscreen stand-in for AudioModel.qml (tests/preview.sh copies it over the
// real one in a throwaway plugin copy) with the same public surface. It
// never imports Quickshell.Services.Pipewire, so previews cannot read or
// change the machine's real outputs; tests/Preview.qml sets the sample state.
QtObject {
  id: root

  property bool optionsActive: false
  property var sinks: [
    { id: 41, name: "sample.studio-headphones", description: "Studio Headphones" },
    { id: 42, name: "sample.desk-speakers", description: "Desk Speakers" },
    { id: 43, name: "sample.monitor-hdmi", description: "Monitor HDMI Audio" }
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
  readonly property var sinkOptions: sinks.map(function(node) {
    return { value: String(node.id), label: Model.sinkLabel(node) }
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
