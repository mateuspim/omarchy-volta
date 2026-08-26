import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "Model.js" as Model

QtObject {
  id: root

  property var defaultSink: Pipewire.defaultAudioSink
  property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  property string resolvedSinkName: ""
  property string error: ""
  property bool channelsLocked: false
  property bool writePending: false
  property real expectedLeft: 0
  property real expectedRight: 0

  readonly property var sinks: {
    var result = []
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (node && node.isSink && !node.isStream) result.push(node)
    }
    if (defaultSink && result.indexOf(defaultSink) < 0) result.unshift(defaultSink)
    return result
  }

  readonly property var sink: {
    if (!defaultSink || resolvedSinkName === "" || String(defaultSink.name) === resolvedSinkName) return defaultSink
    for (var i = 0; i < sinks.length; i++)
      if (String(sinks[i].name) === resolvedSinkName && sinks[i].audio) return sinks[i]
    return defaultSink
  }
  readonly property bool available: !!(sink && sink.audio)
  readonly property var channelNames: {
    var result = []
    if (!available) return result
    var channels = sink.audio.channels || []
    for (var i = 0; i < channels.length; i++) result.push(PwAudioChannel.toString(channels[i]))
    return result
  }
  readonly property var stereo: available ? Model.readStereo(channelNames, sink.audio.volumes) : Model.readStereo([], [])
  readonly property bool stereoSupported: available && stereo.supported
  readonly property bool mono: available && stereo.mono
  readonly property real left: stereo.left
  readonly property real right: stereo.right
  readonly property real balance: Model.balance(left, right)
  readonly property bool muted: available ? sink.audio.muted : false
  readonly property string sinkName: sink ? String(sink.name || "") : ""
  readonly property string sinkId: sink && sink.id !== undefined ? String(sink.id) : ""
  readonly property string sinkLabel: Model.sinkLabel(sink)
  readonly property int sinkIndex: {
    for (var i = 0; i < sinks.length; i++)
      if (sinks[i] === sink || String(sinks[i].name || "") === sinkName) return i
    return -1
  }
  readonly property var sinkOptions: {
    var result = []
    for (var i = 0; i < sinks.length; i++)
      if (sinks[i].id !== undefined)
        result.push({ value: String(sinks[i].id), label: Model.sinkLabel(sinks[i]) })
    return result
  }

  onDefaultSinkChanged: resolvePhysicalSink()

  function resolvePhysicalSink() {
    if (!resolver.running) resolver.running = true
  }

  function validateWritable() {
    if (!available) { error = "No output sink is available."; return false }
    if (!stereoSupported) {
      error = mono ? "This output is mono; independent L/R control is unavailable."
                   : "This output has no front-left/front-right channel map."
      return false
    }
    return true
  }

  function write(leftValue, rightValue) {
    if (!validateWritable()) return
    var next = Model.withStereoVolumes(sink.audio.volumes, stereo.leftIndex, stereo.rightIndex, leftValue, rightValue)
    error = ""
    writePending = true
    expectedLeft = Model.clampVolume(leftValue)
    expectedRight = Model.clampVolume(rightValue)
    sink.audio.volumes = next
    verifyTimer.restart()
  }

  function setLeft(value) {
    var next = Model.clampVolume(value)
    write(next, channelsLocked ? next : right)
  }

  function setRight(value) {
    var next = Model.clampVolume(value)
    write(channelsLocked ? next : left, next)
  }

  function setBalance(value) {
    var pair = Model.applyBalance(left, right, value)
    write(pair.left, pair.right)
  }
  function shiftBalance(delta) { setBalance(balance + delta) }

  function adjustBoth(delta) { write(left + delta, right + delta) }
  function toggleLock() {
    if (!channelsLocked) {
      var average = (left + right) / 2
      write(average, average)
      channelsLocked = true
    } else {
      channelsLocked = false
    }
  }
  function toggleMute() {
    if (!available) { error = "No output sink is available."; return }
    error = ""
    sink.audio.muted = !sink.audio.muted
  }
  function reset() { channelsLocked = false; write(1, 1) }

  function selectSink(name) {
    for (var i = 0; i < sinks.length; i++) {
      var node = sinks[i]
      if (String(node.name || "") !== String(name)) continue
      error = ""
      Pipewire.preferredDefaultAudioSink = node
      if (node.id !== undefined && node.name)
        Quickshell.execDetached(["omarchy-audio-output-set-default", String(node.id), String(node.name)])
      resolveTimer.restart()
      return
    }
    error = "The selected output disappeared. Refreshing devices…"
    resolvePhysicalSink()
  }

  function selectSinkId(id) {
    for (var i = 0; i < sinks.length; i++) {
      if (sinks[i].id !== undefined && String(sinks[i].id) === String(id)) {
        selectSink(String(sinks[i].name || ""))
        return
      }
    }
    error = "The selected output disappeared. Refreshing devices…"
    resolvePhysicalSink()
  }

  function cycleSink(delta) {
    if (sinks.length < 2) return
    var next = (Math.max(0, sinkIndex) + delta + sinks.length) % sinks.length
    if (sinks[next].id !== undefined) selectSinkId(sinks[next].id)
  }

  property PwObjectTracker tracker: PwObjectTracker { objects: root.sinks }

  property Process resolver: Process {
    command: ["omarchy-audio-output-sink"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.resolvedSinkName = String(text).trim()
        if (!root.available) root.error = "No output sink is available."
        else if (root.error === "No output sink is available.") root.error = ""
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.resolvedSinkName = ""
        root.error = "Could not resolve the physical output; using the PipeWire default."
      }
    }
  }

  property Timer resolveTimer: Timer { interval: 250; onTriggered: root.resolvePhysicalSink() }
  property Timer refreshTimer: Timer {
    interval: 15000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.resolvePhysicalSink()
  }
  property Timer verifyTimer: Timer {
    interval: 800
    onTriggered: {
      root.writePending = false
      if (!root.available) root.error = "The output disappeared while changing volume."
      else if (Math.abs(root.left - root.expectedLeft) > 0.015 || Math.abs(root.right - root.expectedRight) > 0.015)
        root.error = "PipeWire did not keep the requested channel levels; another audio policy may be overriding them."
    }
  }
}
