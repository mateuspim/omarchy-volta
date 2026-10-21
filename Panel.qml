import QtQuick
import QtQuick.Controls
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
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
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
      Volta.VoltaMark { tint: button.active ? button.activeColor : button.foreground }
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
    contentWidth: fittedContentWidth(Style.space(400))
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
        spacing: Style.spacing.xl

        PanelHero {
          width: parent.width
          title: "Volta"
          meta: Model.heroMeta(audio.available, audio.mono, root.sinkPosition, audio.sinks.length)
          detail: Model.heroDetail(audio.muted, audio.channelsLocked, audio.balance, audio.stereoSupported)
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component { Volta.VoltaMark { width: Style.space(34); height: Style.space(34); tint: audio.muted ? root.danger : Commons.Color.accent } }
        }

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
            fontFamily: root.fontFamily
            onChanged: function(value) { audio.selectSinkId(value) }
            Accessible.role: Accessible.ComboBox
            Accessible.name: "Output sink"
          }
          PanelActionButton { iconText: "󰅂"; tooltipText: "Next output · Right / Tab"; foreground: root.foreground; enabled: audio.sinks.length > 1; onClicked: { audio.cycleSink(1); keySurface.forceActiveFocus() } }
        }

        Volta.StereoStage {
          width: parent.width
          leftLevel: audio.mono ? audio.volume : audio.left
          rightLevel: audio.mono ? audio.volume : audio.right
          mono: audio.mono
          muted: audio.muted
          available: audio.available
          foreground: root.foreground
          danger: root.danger
          fontFamily: root.fontFamily
        }

        Rectangle {
          visible: audio.error !== "" || !audio.stereoSupported
          width: parent.width
          height: warningRow.implicitHeight + Style.spacing.lg * 2
          radius: Style.cornerRadius
          color: Util.alpha(root.danger, 0.12)
          border.width: Math.max(1, Style.normalBorderWidth)
          border.color: Util.alpha(root.danger, 0.55)
          Row {
            id: warningRow
            anchors.fill: parent
            anchors.margins: Style.spacing.lg
            spacing: Style.spacing.lg
            Text { id: warningIcon; text: "󰀦"; color: root.danger; font.family: root.fontFamily; font.pixelSize: Style.font.title }
            Text {
              width: parent.width - warningIcon.width - parent.spacing
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: audio.error !== "" ? audio.error : (audio.mono ? "Mono output: volume and mute work; independent channels need stereo." : "This output has no front-left and front-right channels.")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xxs
          Volta.LevelSlider { bar: root.bar; visible: audio.mono; width: parent.width; label: "VOLUME"; keys: ["J", "K"]; value: audio.volume; enabled: audio.available; selected: root.keyboardRow === 1; foreground: root.foreground; danger: root.danger; fontFamily: root.fontFamily; Accessible.role: Accessible.Slider; Accessible.name: "Volume"; Accessible.description: Model.percent(audio.volume); onMoved: function(value) { audio.setVolume(value) } }
          Volta.LevelSlider { bar: root.bar; visible: !audio.mono; width: parent.width; label: "LEFT"; keys: ["J", "K"]; value: audio.left; enabled: audio.stereoSupported; selected: root.keyboardRow === 1; foreground: root.foreground; danger: root.danger; fontFamily: root.fontFamily; Accessible.role: Accessible.Slider; Accessible.name: "Left"; Accessible.description: Model.percent(audio.left); onMoved: function(value) { audio.setLeft(value) } }
          Volta.LevelSlider { bar: root.bar; visible: !audio.mono; width: parent.width; label: "RIGHT"; keys: ["⇧J", "⇧K"]; value: audio.right; enabled: audio.stereoSupported; selected: root.keyboardRow === 2; foreground: root.foreground; danger: root.danger; fontFamily: root.fontFamily; Accessible.role: Accessible.Slider; Accessible.name: "Right"; Accessible.description: Model.percent(audio.right); onMoved: function(value) { audio.setRight(value) } }
          Volta.LevelSlider { bar: root.bar; width: parent.width; label: "BALANCE"; keys: ["H", "L"]; centred: true; minimum: -1; maximum: 1; valueText: Model.balanceLabel(audio.balance); value: audio.balance; enabled: audio.stereoSupported; selected: root.keyboardRow === 3; foreground: root.foreground; danger: root.danger; fontFamily: root.fontFamily; Accessible.role: Accessible.Slider; Accessible.name: "Stereo balance"; Accessible.description: valueText; onMoved: function(value) { audio.setBalance(value) } }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.md
          Button { width: (parent.width - parent.spacing * 2) / 3; bordered: true; text: "Link"; iconText: audio.channelsLocked ? "󰌷" : "󰌸"; tooltipText: "Shift+L · Link channels at equal volume"; hasCursor: root.keyboardRow === 4; selected: audio.channelsLocked; enabled: audio.stereoSupported; opacity: enabled ? 1 : 0.45; foreground: root.foreground; fontFamily: root.fontFamily; focusable: true; Accessible.role: Accessible.Button; Accessible.name: audio.channelsLocked ? "Unlink channels" : "Link channels"; onClicked: { audio.toggleLock(); keySurface.forceActiveFocus() } }
          Button { width: (parent.width - parent.spacing * 2) / 3; bordered: true; text: "Mute"; iconText: "󰝟"; tooltipText: "M · Mute or unmute the output"; hasCursor: root.keyboardRow === 5; selected: audio.muted; accent: audio.muted ? root.danger : Commons.Color.accent; foreground: root.foreground; fontFamily: root.fontFamily; focusable: true; Accessible.role: Accessible.Button; Accessible.name: audio.muted ? "Unmute output" : "Mute output"; onClicked: { audio.toggleMute(); keySurface.forceActiveFocus() } }
          Button { width: (parent.width - parent.spacing * 2) / 3; bordered: true; text: "Reset"; iconText: "󰑐"; tooltipText: "R · Both channels to 100 % and unlink"; hasCursor: root.keyboardRow === 6; foreground: root.foreground; fontFamily: root.fontFamily; focusable: true; Accessible.role: Accessible.Button; Accessible.name: "Reset output volume"; onClicked: { audio.reset(); keySurface.forceActiveFocus() } }
        }

        PanelSeparator { foreground: root.foreground }

        Flow {
          width: parent.width
          spacing: Style.spacing.xl
          Repeater {
            model: Model.footerHints(audio.stereoSupported)
            Volta.KeyHints { required property var modelData; keys: modelData.keys; label: modelData.label; foreground: root.foreground; fontFamily: root.fontFamily }
          }
        }
      }
    }
  }
}
