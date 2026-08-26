import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "Model.js" as Model

QtObject {
  id: root

  property var defaultSink: Pipewire.defaultAudioSink
  property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  property bool optionsActive: false
  property string resolvedSinkName: ""
  property var sinkAvailability: ({})
  property bool sinkAvailabilityLoaded: false
  property int resolverRequestedGeneration: 0
  property int resolverRunningGeneration: 0
  property bool resolverPending: false
  property string resolverError: ""
  property string controlError: ""
  property string verificationError: ""
  readonly property string error: controlError !== "" ? controlError : (verificationError !== "" ? verificationError : resolverError)
  property bool channelsLocked: false
  property bool writePending: false
  property real expectedLeft: 0
  property real expectedRight: 0
  property real expectedVolume: 0
  property string expectedSinkId: ""

  readonly property var candidateSinks: {
    var result = []
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (node && node.isSink && !node.isStream) result.push(node)
    }
    if (defaultSink && result.indexOf(defaultSink) < 0) result.unshift(defaultSink)
    return result
  }

  readonly property var sinks: {
    var result = []
    for (var i = 0; i < candidateSinks.length; i++) {
      var node = candidateSinks[i]
      if (node === defaultSink || sinkAvailable(node)) result.push(node)
    }
    return result
  }

  readonly property var sink: {
    if (!defaultSink || resolvedSinkName === "" || String(defaultSink.name) === resolvedSinkName) return defaultSink
    for (var i = 0; i < candidateSinks.length; i++)
      if (String(candidateSinks[i].name) === resolvedSinkName && candidateSinks[i].audio) return candidateSinks[i]
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
  readonly property real volume: available ? Model.clampVolume(sink.audio.volume) : 0
  readonly property real balance: Model.balance(left, right)
  readonly property bool muted: available ? sink.audio.muted : false
  readonly property string sinkName: sink ? String(sink.name || "") : ""
  readonly property string effectiveSinkId: sink && sink.id !== undefined ? String(sink.id) : sinkName
  readonly property string sinkId: defaultSink && defaultSink.id !== undefined ? String(defaultSink.id) : ""
  readonly property string sinkLabel: Model.sinkLabel(sink)
  readonly property int sinkIndex: {
    for (var i = 0; i < sinks.length; i++)
      if (sinks[i] === defaultSink || String(sinks[i].name || "") === String(defaultSink ? defaultSink.name || "" : "")) return i
    return -1
  }
  readonly property var sinkOptions: {
    var result = []
    for (var i = 0; i < sinks.length; i++)
      if (sinks[i].id !== undefined)
        result.push({ value: String(sinks[i].id), label: Model.sinkLabel(sinks[i]) })
    return result
  }

  onSinkChanged: {
    channelsLocked = false
    verifyTimer.stop()
    writePending = false
    controlError = ""
    verificationError = ""
  }
  onDefaultSinkChanged: {
    resolvePhysicalSink()
    refreshAvailability()
  }

  function sinkAvailable(node) {
    if (!node || !node.name || !sinkAvailabilityLoaded) return true
    return sinkAvailability[String(node.name)] !== false
  }

  function refreshAvailability() {
    if (!availabilityProc.running) availabilityProc.running = true
  }

  function resolvePhysicalSink() {
    resolverRequestedGeneration++
    if (resolver.running) {
      resolverPending = true
      return
    }
    startResolver()
  }

  function startResolver() {
    resolverPending = false
    resolverRunningGeneration = resolverRequestedGeneration
    resolver.running = true
  }

  function validateWritable() {
    if (!available) { controlError = "No output sink is available."; return false }
    if (!stereoSupported) {
      controlError = mono ? "This output is mono; independent L/R control is unavailable."
                          : "This output has no front-left/front-right channel map."
      return false
    }
    return true
  }

  function write(leftValue, rightValue) {
    if (!validateWritable()) return false
    var next = Model.withStereoVolumes(sink.audio.volumes, stereo.leftIndex, stereo.rightIndex, leftValue, rightValue)
    controlError = ""
    verificationError = ""
    writePending = true
    expectedLeft = Model.clampVolume(leftValue)
    expectedRight = Model.clampVolume(rightValue)
    expectedSinkId = effectiveSinkId
    sink.audio.volumes = next
    verifyTimer.restart()
    return true
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

  function setVolume(value) {
    if (!available) { controlError = "No output sink is available."; return }
    var next = Model.clampVolume(value)
    controlError = ""
    verificationError = ""
    writePending = true
    expectedVolume = next
    expectedSinkId = effectiveSinkId
    sink.audio.volume = next
    verifyTimer.restart()
  }

  function adjustBoth(delta) {
    if (mono) setVolume(volume + delta)
    else write(left + delta, right + delta)
  }
  function toggleLock() {
    if (!channelsLocked) {
      var average = (left + right) / 2
      if (write(average, average)) channelsLocked = true
    } else {
      channelsLocked = false
    }
  }
  function toggleMute() {
    if (!available) { controlError = "No output sink is available."; return }
    controlError = ""
    sink.audio.muted = !sink.audio.muted
  }
  function reset() {
    channelsLocked = false
    if (mono) setVolume(1)
    else write(1, 1)
  }

  function selectSink(name) {
    for (var i = 0; i < sinks.length; i++) {
      var node = sinks[i]
      if (String(node.name || "") !== String(name)) continue
      controlError = ""
      Pipewire.preferredDefaultAudioSink = node
      if (node.id !== undefined && node.name)
        Quickshell.execDetached(["omarchy-audio-output-set-default", String(node.id), String(node.name)])
      resolveTimer.restart()
      return
    }
    controlError = "The selected output disappeared. Refreshing devices…"
    resolvePhysicalSink()
  }

  function selectSinkId(id) {
    for (var i = 0; i < sinks.length; i++) {
      if (sinks[i].id !== undefined && String(sinks[i].id) === String(id)) {
        selectSink(String(sinks[i].name || ""))
        return
      }
    }
    controlError = "The selected output disappeared. Refreshing devices…"
    resolvePhysicalSink()
  }

  function cycleSink(delta) {
    if (sinks.length < 2) return
    var next = (Math.max(0, sinkIndex) + delta + sinks.length) % sinks.length
    if (sinks[next].id !== undefined) selectSinkId(sinks[next].id)
  }

  property PwObjectTracker tracker: PwObjectTracker { objects: root.candidateSinks }

  property Process availabilityProc: Process {
    property string output: ""
    command: ["omarchy-audio-sink-availability"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: availabilityProc.output = String(text)
    }
    onStarted: output = ""
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.sinkAvailability = Model.parseSinkAvailability(output)
        root.sinkAvailabilityLoaded = true
      }
    }
  }

  property Process resolver: Process {
    property string output: ""
    command: ["omarchy-audio-output-sink"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: resolver.output = String(text).trim()
    }
    onStarted: output = ""
    onExited: function(exitCode) {
      if (root.resolverRunningGeneration === root.resolverRequestedGeneration) {
        if (exitCode === 0) {
          root.resolvedSinkName = output
          root.resolverError = root.available ? "" : "No output sink is available."
        } else {
          root.resolvedSinkName = ""
          root.resolverError = "Could not resolve the physical output; using the PipeWire default."
        }
      }
      if (root.resolverPending || root.resolverRunningGeneration < root.resolverRequestedGeneration)
        root.resolverRetryTimer.restart()
    }
  }

  property Timer resolverRetryTimer: Timer { interval: 0; onTriggered: root.startResolver() }
  property Timer resolveTimer: Timer { interval: 250; onTriggered: root.resolvePhysicalSink() }
  property Timer refreshTimer: Timer {
    interval: 15000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.resolvePhysicalSink()
  }
  property Timer availabilityTimer: Timer {
    interval: 5000
    repeat: true
    running: root.optionsActive
    triggeredOnStart: true
    onTriggered: root.refreshAvailability()
  }
  property Timer verifyTimer: Timer {
    interval: 800
    onTriggered: {
      root.writePending = false
      if (root.effectiveSinkId !== root.expectedSinkId) {
        root.verificationError = ""
        return
      }
      if (!root.available) root.verificationError = "The output disappeared while changing volume."
      else if (root.mono && Math.abs(root.volume - root.expectedVolume) > 0.015)
        root.verificationError = "PipeWire did not keep the requested volume; another audio policy may be overriding it."
      else if (!root.mono && (Math.abs(root.left - root.expectedLeft) > 0.015 || Math.abs(root.right - root.expectedRight) > 0.015))
        root.verificationError = "PipeWire did not keep the requested channel levels; another audio policy may be overriding them."
      else root.verificationError = ""
    }
  }
}
