import QtQuick
import QtTest
import Quickshell
import qs.Commons
import qs.Commons as Commons
import "plugin" as Volta

// Offscreen visual review: draws the Volta popup for each sample scene and
// saves one PNG per scene into VOLTA_PREVIEW_DIR. Run through tests/preview.sh,
// which swaps in the fake AudioModel and the KeyboardPanel stand-in.
ShellRoot {
  id: root

  readonly property var audio: Volta.AudioService.audio
  readonly property var scenes: [
    { name: "headphones", outputs: "three", sinkIndex: 0, left: 0.64, right: 1.18, locked: false, muted: false, mono: false, row: 3 },
    { name: "speakers", outputs: "three", sinkIndex: 1, left: 0.8, right: 0.8, locked: true, muted: false, mono: false, row: 0 },
    { name: "mono", outputs: "three", sinkIndex: 2, left: 0.72, right: 0.72, locked: false, muted: false, mono: true, row: 1 },
    { name: "muted", outputs: "three", sinkIndex: 0, left: 0.9, right: 0.55, locked: false, muted: true, mono: false, row: 5 },
    { name: "six-outputs", outputs: "six", sinkIndex: 1, left: 0.8, right: 0.8, locked: false, muted: false, mono: false, row: 0 },
    { name: "six-outputs-expanded", outputs: "six", sinkIndex: 3, left: 0.7, right: 0.75, locked: false, muted: false, mono: false, row: 0, expanded: true }
  ]
  // The fake model's three sample outputs, plus three more for the overflow
  // scenes. Names, buses and addresses are made up.
  property var threeSinks: []
  readonly property var extraSinks: [
    { id: 44, name: "alsa_output.pci-sample_gpu.hdmi-stereo", description: "Living Room TV", ready: true,
      properties: { "device.api": "alsa", "device.bus": "pci", "device.profile.name": "hdmi-stereo" }, channels: ["FrontLeft", "FrontRight"] },
    { id: 45, name: "bluez_output.sample_earbuds.1", description: "Wireless Earbuds", ready: true,
      properties: { "device.api": "bluez5" }, channels: ["FrontLeft", "FrontRight"] },
    { id: 46, name: "bluez_output.sample_speaker.1", description: "Portable Speaker", ready: true,
      properties: { "device.api": "bluez5" }, channels: ["FrontLeft", "FrontRight"] }
  ]
  property int sceneIndex: 0
  property Item card: null

  TestCase { id: finder; when: false }

  QtObject {
    id: fakeBar
    property string position: "top"
    property bool vertical: false
    property int barSize: Style.bar.sizeHorizontal
    property color foreground: Commons.Color.foreground
    property color barForeground: Commons.Color.foreground
    property color urgent: Commons.Color.urgent
    property color background: Commons.Color.popups.background
    property string fontFamily: Style.font.family
    property bool foregroundAnimationEnabled: false
    property var activePopout: null
    function requestPopout(owner) { activePopout = owner }
    function releasePopout(owner) { if (activePopout === owner) activePopout = null }
  }

  Volta.Panel { id: widget; bar: fakeBar }

  FloatingWindow {
    title: "Volta · sample preview"
    implicitWidth: 520
    implicitHeight: 1400
    color: Commons.Color.background
    Item { id: mount; anchors.fill: parent; anchors.margins: 20 }
  }

  function applyScene(scene) {
    if (threeSinks.length === 0) threeSinks = audio.sinks.slice()
    audio.sinks = scene.outputs === "six"
      ? [threeSinks[0], threeSinks[1], extraSinks[0], extraSinks[1], extraSinks[2], threeSinks[2]]
      : threeSinks
    audio.sinkIndex = scene.sinkIndex
    audio.mono = scene.mono
    audio.stereoSupported = !scene.mono
    audio.left = scene.left
    audio.right = scene.right
    audio.volume = scene.left
    audio.channelsLocked = scene.locked
    audio.muted = scene.muted
    widget.keyboardRow = scene.row
    widget.outputsExpanded = !!scene.expanded
  }

  function capture() {
    if (sceneIndex >= scenes.length) {
      console.log("VOLTA_PREVIEW_OK")
      Qt.quit()
      return
    }
    var scene = scenes[sceneIndex]
    applyScene(scene)
    Qt.callLater(function() {
      grabTimer.restart()
    })
  }

  Timer {
    id: grabTimer
    interval: 400
    onTriggered: {
      var name = root.scenes[root.sceneIndex].name
      var ok = root.card.grabToImage(function(result) {
        var path = Quickshell.env("VOLTA_PREVIEW_DIR") + "/" + name + ".png"
        if (!result.saveToFile(path)) {
          console.error("VOLTA_PREVIEW_FAILED: cannot save " + path)
          Qt.exit(1)
          return
        }
        root.sceneIndex++
        root.capture()
      })
      if (!ok) { console.error("VOLTA_PREVIEW_FAILED: grab"); Qt.exit(1) }
    }
  }

  Timer {
    interval: 300
    running: true
    onTriggered: {
      root.card = finder.findChild(widget, "voltaPreviewPanel")
      if (!root.card) { console.error("VOLTA_PREVIEW_FAILED: no panel stand-in"); Qt.exit(1); return }
      root.card.parent = mount
      widget.toggle()
      root.capture()
    }
  }
}
