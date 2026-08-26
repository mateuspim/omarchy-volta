import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Ui
import qs.Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "pym.volta"
  ipcTarget: "pym.volta"

  property int keyboardRow: 0
  property real wheelAccumulator: 0
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color subtle: Qt.darker(foreground, 1.45)
  readonly property color danger: bar ? bar.urgent : Color.urgent
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function icon() {
    if (!audio.available) return "󰖁"
    if (audio.muted || Math.max(audio.left, audio.right) <= 0) return "󰝟"
    if (!audio.stereoSupported) return "󰕾"
    if (Math.abs(audio.balance) >= 0.12) return audio.balance < 0 ? "󰋋" : "󰋎"
    return Math.max(audio.left, audio.right) > 1 ? "󱄠" : "󰕾"
  }
  function adjust(row, delta) {
    if (row === 1) audio.setLeft(audio.left + delta)
    else if (row === 2) audio.setRight(audio.right + delta)
    else if (row === 3) audio.setBalance(audio.balance + delta * 4)
  }

  AudioModel { id: audio }

  BarIconButton {
    id: button
    bar: root.bar
    iconComponent: Component {
      Item {
        Image {
          id: voltaMark
          anchors.fill: parent
          source: "assets/volta-bar-icon.png"
          fillMode: Image.PreserveAspectFit
          sourceSize.width: Math.round(width * 4)
          sourceSize.height: Math.round(height * 4)
          visible: false
          layer.enabled: true
        }
        MultiEffect {
          anchors.fill: voltaMark
          source: voltaMark
          colorization: 1.0
          colorizationColor: button.active ? button.activeColor : button.foreground
        }
      }
    }
    active: root.opened || audio.muted || Math.abs(audio.balance) >= 0.12
    tooltipText: audio.available
      ? audio.sinkLabel + "\nL " + Model.percent(audio.left) + "  R " + Model.percent(audio.right) + " · " + Model.balanceLabel(audio.balance)
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

  PopupCard {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: fittedContentWidth(380)
    contentHeight: fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      anchors.fill: parent
      blocked: sinkPicker.popupOpen
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.keyboardRow = Math.max(0, Math.min(6, root.keyboardRow + dy))
        if (dx !== 0 && root.keyboardRow >= 1 && root.keyboardRow <= 3) root.adjust(root.keyboardRow, dx * 0.01)
      }
      onActivateRequested: {
        if (root.keyboardRow === 0) sinkPicker.open()
        else if (root.keyboardRow === 4) audio.channelsLocked = !audio.channelsLocked
        else if (root.keyboardRow === 5) audio.toggleMute()
        else if (root.keyboardRow === 6) audio.reset()
      }
      onTabRequested: function(direction) { root.keyboardRow = Math.max(0, Math.min(6, root.keyboardRow + direction)) }
      onTextKey: function(key) {
        if (key === "m") audio.toggleMute()
        else if (key === "r") audio.reset()
        else if (key === "c") audio.channelsLocked = !audio.channelsLocked
      }

      Column {
        id: content
        width: popup.contentWidth - popup.padding * 2
        spacing: Style.spacing.lg

        Row {
          width: parent.width
          spacing: Style.spacing.md
          Text { text: root.icon(); color: root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.iconLarge; anchors.verticalCenter: parent.verticalCenter }
          Column {
            width: parent.width - parent.spacing - Style.space(36)
            Text { text: "Volta"; color: root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.title; font.bold: true }
            Text { width: parent.width; text: audio.sinkLabel; color: root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
          }
        }

        Rectangle {
          visible: audio.error !== "" || !audio.stereoSupported
          width: parent.width
          height: warningText.implicitHeight + Style.spacing.md * 2
          radius: Style.cornerRadius
          color: Style.hoverFillFor(root.danger, Color.accent)
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

        Dropdown {
          id: sinkPicker
          width: parent.width
          label: "OUTPUT"
          value: audio.sinkName
          options: audio.sinkOptions
          hasCursor: root.keyboardRow === 0
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          onChanged: function(value) { audio.selectSink(value) }
        }

        ChannelSlider { width: parent.width; label: "LEFT"; value: audio.left; enabled: audio.stereoSupported; selected: root.keyboardRow === 1; onMoved: function(value) { audio.setLeft(value) } }
        ChannelSlider { width: parent.width; label: "RIGHT"; value: audio.right; enabled: audio.stereoSupported; selected: root.keyboardRow === 2; onMoved: function(value) { audio.setRight(value) } }

        Column {
          width: parent.width
          spacing: Style.spacing.xs
          Row {
            width: parent.width
            Text { text: "BALANCE"; color: root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
            Text { width: parent.width - x; horizontalAlignment: Text.AlignRight; text: Model.balanceLabel(audio.balance); color: root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption }
          }
          PanelSlider { width: parent.width; value: audio.balance; minimum: -1; maximum: 1; step: 0.05; tickCount: 3; enabled: audio.stereoSupported; onMoved: function(value) { audio.setBalance(value) } }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm
          Button { width: (parent.width - parent.spacing * 2) / 3; text: audio.channelsLocked ? "Linked" : "Independent"; iconText: audio.channelsLocked ? "󰌷" : "󰌸"; selected: root.keyboardRow === 4; active: audio.channelsLocked; focusable: true; onClicked: audio.channelsLocked = !audio.channelsLocked }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: audio.muted ? "Unmute" : "Mute"; iconText: audio.muted ? "󰕾" : "󰝟"; selected: root.keyboardRow === 5; focusable: true; onClicked: audio.toggleMute() }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: "Reset"; iconText: "󰑐"; selected: root.keyboardRow === 6; focusable: true; onClicked: audio.reset() }
        }

        Text { width: parent.width; text: "Wheel: both · ↑↓ select · ←→ adjust · M mute · C link · R reset"; color: root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
      }
    }
  }

  component ChannelSlider: Column {
    id: channel
    property string label: ""
    property real value: 0
    property bool selected: false
    signal moved(real value)
    spacing: Style.spacing.xs
    opacity: enabled ? 1 : 0.45
    Row {
      width: parent.width
      Text { text: channel.label; color: channel.selected ? root.foreground : root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
      Text { width: parent.width - x; horizontalAlignment: Text.AlignRight; text: Model.percent(channel.value); color: channel.value > 1 ? root.danger : root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: channel.value > 1 }
    }
    PanelSlider { width: parent.width; value: channel.value; minimum: 0; maximum: 1.5; step: 0.05; tickCount: 4; fillColor: channel.value > 1 ? root.danger : root.foreground; onMoved: function(value) { channel.moved(value) } }
  }
}
