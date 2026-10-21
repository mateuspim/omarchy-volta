import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "." as Volta
import "Model.js" as Model

Panel {
  id: root
  moduleName: "pym.volta"
  manageIpc: false

  property int keyboardRow: 0
  property real wheelAccumulator: 0
  property var displaySinkOptions: []
  readonly property var audio: Volta.AudioService.audio
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color subtle: Qt.darker(foreground, 1.45)
  readonly property color danger: bar ? bar.urgent : Commons.Color.urgent
  readonly property int sinkPosition: audio.sinkIndex >= 0 ? audio.sinkIndex + 1 : (audio.sinks.length > 0 ? 1 : 0)
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) {
      refreshSinkOptions()
      Qt.callLater(function() { keySurface.forceActiveFocus() })
    } else {
      sinkOptionsTimer.stop()
      displaySinkOptions = []
    }
  }

  function scheduleSinkOptionsRefresh() {
    if (opened) sinkOptionsTimer.restart()
  }
  function refreshSinkOptions() {
    if (opened) displaySinkOptions = audio.sinkOptions.slice()
  }

  function icon() {
    if (!audio.available) return "󰖁"
    if (audio.muted || Math.max(audio.left, audio.right) <= 0) return "󰝟"
    if (!audio.stereoSupported) return "󰕾"
    if (Math.abs(audio.balance) >= 0.12) return audio.balance < 0 ? "󰋋" : "󰋎"
    return Math.max(audio.left, audio.right) > 1 ? "󱄠" : "󰕾"
  }
  function adjust(row, delta) {
    if (row === 1) {
      if (audio.mono) audio.setVolume(audio.volume + delta)
      else audio.setLeft(audio.left + delta)
    } else if (row === 2) audio.setRight(audio.right + delta)
    else if (row === 3) audio.setBalance(audio.balance + delta * 4)
  }
  function handleKey(event) {
    if (sinkPicker.popupOpen) return
    if (event.key === Qt.Key_Escape || event.text === "q") { root.close(); event.accepted = true; return }
    if (event.key === Qt.Key_Tab) { audio.cycleSink((event.modifiers & Qt.ShiftModifier) ? -1 : 1); event.accepted = true; return }
    if (event.key === Qt.Key_Backtab) { audio.cycleSink(-1); event.accepted = true; return }
    if (event.key === Qt.Key_Left) {
      if (keyboardRow === 0) audio.cycleSink(-1)
      else adjust(keyboardRow, -0.05)
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Right) {
      if (keyboardRow === 0) audio.cycleSink(1)
      else adjust(keyboardRow, 0.05)
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Up) { keyboardRow = Math.max(0, keyboardRow - 1); event.accepted = true; return }
    if (event.key === Qt.Key_Down) { keyboardRow = Math.min(6, keyboardRow + 1); event.accepted = true; return }
    if (event.text === "k") { audio.mono ? audio.setVolume(audio.volume + 0.05) : audio.setLeft(audio.left + 0.05); event.accepted = true; return }
    if (event.text === "j") { audio.mono ? audio.setVolume(audio.volume - 0.05) : audio.setLeft(audio.left - 0.05); event.accepted = true; return }
    if (event.text === "K") { audio.mono ? audio.setVolume(audio.volume + 0.05) : audio.setRight(audio.right + 0.05); event.accepted = true; return }
    if (event.text === "J") { audio.mono ? audio.setVolume(audio.volume - 0.05) : audio.setRight(audio.right - 0.05); event.accepted = true; return }
    if (event.key === Qt.Key_L && (event.modifiers & Qt.ShiftModifier)) { audio.toggleLock(); event.accepted = true; return }
    if (event.text === "h") { audio.shiftBalance(-0.03); event.accepted = true; return }
    if (event.text === "l") { audio.shiftBalance(0.03); event.accepted = true; return }
    if (event.text === "m") { audio.toggleMute(); event.accepted = true; return }
    if (event.text === "r") { audio.reset(); event.accepted = true; return }
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
      if (keyboardRow === 0) sinkPicker.open()
      else if (keyboardRow === 4) audio.toggleLock()
      else if (keyboardRow === 5) audio.toggleMute()
      else if (keyboardRow === 6) audio.reset()
      else { event.accepted = false; return }
      event.accepted = true
    }
  }

  Connections {
    target: audio
    function onSinkOptionsChanged() { root.scheduleSinkOptionsRefresh() }
  }

  Timer {
    id: sinkOptionsTimer
    interval: 75
    onTriggered: root.refreshSinkOptions()
  }

  BarIconButton {
    id: button
    bar: root.bar
    iconComponent: Component {
      VoltaMark { tint: button.active ? button.activeColor : button.foreground }
    }
    active: root.opened || audio.muted || Math.abs(audio.balance) >= 0.12
    Accessible.role: Accessible.Button
    Accessible.name: "Volta audio controls"
    tooltipText: audio.available
      ? audio.sinkLabel + (audio.mono
          ? "\nVolume " + Model.percent(audio.volume)
          : "\nL " + Model.percent(audio.left) + "  R " + Model.percent(audio.right) + " · " + Model.balanceLabel(audio.balance))
      : "Volta · No output"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.toggle()
      else if (mouseButton === Qt.RightButton) audio.toggleMute()
      else if (mouseButton === Qt.MiddleButton) audio.reset()
    }
    onWheelMoved: function(delta) {
      root.wheelAccumulator += delta
      while (Math.abs(root.wheelAccumulator) >= 120) {
        var direction = root.wheelAccumulator > 0 ? 1 : -1
        audio.adjustBoth(direction * 0.05)
        root.wheelAccumulator -= direction * 120
      }
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keySurface
    contentWidth: fittedContentWidth(400)
    contentHeight: fittedContentHeight(content.implicitHeight)

    Item {
      id: keySurface
      anchors.fill: parent
      focus: root.opened
      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) { root.handleKey(event) }

      Column {
        id: content
        width: popup.contentWidth - popup.padding * 2
        spacing: Style.spacing.lg

        PanelHero {
          width: parent.width
          title: "Volta"
          meta: audio.available
            ? (audio.mono ? Model.percent(audio.volume) + " volume" : Model.percent(audio.left) + " left  ·  " + Model.percent(audio.right) + " right")
            : "No output available"
          detail: audio.muted ? "Muted" : (audio.channelsLocked ? "Linked" : Model.balanceLabel(audio.balance))
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          iconComponent: Component { VoltaMark { width: Style.space(34); height: Style.space(34); tint: audio.muted ? root.danger : root.foreground } }
        }

        Rectangle {
          visible: audio.error !== "" || !audio.stereoSupported
          width: parent.width
          height: warningText.implicitHeight + Style.spacing.md * 2
          radius: Style.cornerRadius
          color: Style.hoverFillFor(root.danger, Commons.Color.accent)
          Text {
            id: warningText
            anchors.fill: parent
            anchors.margins: Style.spacing.md
            text: audio.error !== "" ? audio.error : (audio.mono ? "Mono output: volume and mute remain available; independent channels require stereo." : "This output does not expose front-left and front-right channels.")
            color: root.foreground
            font.family: bar ? bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xs
          PanelSectionHeader { text: "OUTPUT  ·  ← / →"; foreground: root.foreground; fontFamily: bar ? bar.fontFamily : Style.font.family }
          Row {
            width: parent.width
            spacing: Style.spacing.xs
            PanelActionButton { iconText: "󰅁"; tooltipText: "Previous output · Left / Shift+Tab"; foreground: root.foreground; enabled: audio.sinks.length > 1; onClicked: { audio.cycleSink(-1); keySurface.forceActiveFocus() } }
            Dropdown {
              id: sinkPicker
              width: parent.width - parent.spacing * 2 - Style.space(44)
              showLabel: false
              value: audio.sinkId
              options: root.displaySinkOptions
              hasCursor: root.keyboardRow === 0
              foreground: root.foreground
              fontFamily: bar ? bar.fontFamily : Style.font.family
              onChanged: function(value) { audio.selectSinkId(value) }
              Accessible.role: Accessible.ComboBox
              Accessible.name: "Output sink"
            }
            PanelActionButton { iconText: "󰅂"; tooltipText: "Next output · Right / Tab"; foreground: root.foreground; enabled: audio.sinks.length > 1; onClicked: { audio.cycleSink(1); keySurface.forceActiveFocus() } }
          }
          Text { width: parent.width; visible: audio.sinks.length > 1; text: root.sinkPosition + " of " + audio.sinks.length; color: root.subtle; horizontalAlignment: Text.AlignHCenter; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.sm
          PanelSectionHeader { text: "CHANNELS"; foreground: root.foreground; fontFamily: bar ? bar.fontFamily : Style.font.family }
          ChannelSlider { visible: audio.mono; width: parent.width; label: "VOLUME  ·  J / K"; value: audio.volume; enabled: audio.available; selected: root.keyboardRow === 1; onMoved: function(value) { audio.setVolume(value) } }
          ChannelSlider { visible: !audio.mono; width: parent.width; label: "LEFT  ·  J / K"; value: audio.left; enabled: audio.stereoSupported; selected: root.keyboardRow === 1; onMoved: function(value) { audio.setLeft(value) } }
          ChannelSlider { visible: !audio.mono; width: parent.width; label: "RIGHT  ·  ⇧J / ⇧K"; value: audio.right; enabled: audio.stereoSupported; selected: root.keyboardRow === 2; onMoved: function(value) { audio.setRight(value) } }
        }

        Column {
          id: balanceSection
          width: parent.width
          spacing: Style.spacing.xs
          Accessible.role: Accessible.Slider
          Accessible.name: "Stereo balance"
          Accessible.description: Model.balanceLabel(audio.balance)
          Row {
            width: parent.width
            Text { text: "BALANCE  ·  H / L"; color: root.keyboardRow === 3 ? root.foreground : root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
            Text { width: parent.width - x; horizontalAlignment: Text.AlignRight; text: Model.balanceLabel(audio.balance); color: Math.abs(audio.balance) < 0.005 ? Commons.Color.accent : root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
          }
          PanelSlider { width: parent.width; value: audio.balance; minimum: -1; maximum: 1; step: 0.05; tickCount: 3; enabled: audio.stereoSupported; fillColor: root.keyboardRow === 3 ? Commons.Color.accent : root.foreground; knobColor: fillColor; onMoved: function(value) { audio.setBalance(value) } }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm
          Button { width: (parent.width - parent.spacing * 2) / 3; text: (audio.channelsLocked ? "Linked" : "Link") + "  ⇧L"; iconText: audio.channelsLocked ? "󰌷" : "󰌸"; tooltipText: "Shift+L · Link channels at equal volume"; selected: root.keyboardRow === 4; active: audio.channelsLocked; enabled: audio.stereoSupported; focusable: true; Accessible.role: Accessible.Button; Accessible.name: audio.channelsLocked ? "Unlink channels" : "Link channels"; onClicked: { audio.toggleLock(); keySurface.forceActiveFocus() } }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: (audio.muted ? "Unmute" : "Mute") + "  M"; iconText: audio.muted ? "󰕾" : "󰝟"; selected: root.keyboardRow === 5; focusable: true; Accessible.role: Accessible.Button; Accessible.name: audio.muted ? "Unmute output" : "Mute output"; onClicked: { audio.toggleMute(); keySurface.forceActiveFocus() } }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: "Reset  R"; iconText: "󰑐"; selected: root.keyboardRow === 6; focusable: true; Accessible.role: Accessible.Button; Accessible.name: "Reset output volume"; onClicked: { audio.reset(); keySurface.forceActiveFocus() } }
        }
      }
    }
  }

  component ChannelSlider: Column {
    id: channel
    property string label: ""
    property real value: 0
    property bool selected: false
    signal moved(real value)
    Accessible.role: Accessible.Slider
    Accessible.name: label.replace(/\s*·.*$/, "")
    Accessible.description: Model.percent(value)
    spacing: Style.spacing.xs
    opacity: enabled ? 1 : 0.45
    Row {
      width: parent.width
      Text { text: channel.label; color: channel.selected ? root.foreground : root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
      Text { width: parent.width - x; horizontalAlignment: Text.AlignRight; text: Model.percent(channel.value); color: channel.value > 1 ? root.danger : root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: channel.value > 1 }
    }
    PanelSlider { width: parent.width; value: channel.value; minimum: 0; maximum: 1.5; step: 0.05; tickCount: 4; fillColor: channel.value > 1 ? root.danger : root.foreground; onMoved: function(value) { channel.moved(value) } }
  }

  component VoltaMark: Item {
    id: mark
    property color tint: root.foreground
    implicitWidth: Style.space(28)
    implicitHeight: Style.space(28)
    Image {
      id: markSource
      anchors.fill: parent
      source: "assets/volta-bar-icon.png"
      fillMode: Image.PreserveAspectFit
      sourceSize.width: Math.max(64, Math.round(width * 4))
      sourceSize.height: Math.max(64, Math.round(height * 4))
      visible: false
      layer.enabled: true
    }
    MultiEffect {
      anchors.fill: markSource
      source: markSource
      colorization: 1.0
      colorizationColor: mark.tint
    }
  }
}
