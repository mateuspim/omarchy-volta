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
  readonly property int sinkPosition: {
    for (var i = 0; i < audio.sinks.length; i++)
      if (String(audio.sinks[i].name || "") === audio.sinkName) return i + 1
    return audio.sinks.length > 0 ? 1 : 0
  }
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
  function handleKey(event) {
    if (sinkPicker.popupOpen) return
    if (event.key === Qt.Key_Escape || event.text === "q") { root.close(); event.accepted = true; return }
    if (event.key === Qt.Key_Tab) { audio.cycleSink((event.modifiers & Qt.ShiftModifier) ? -1 : 1); event.accepted = true; return }
    if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left) { audio.cycleSink(-1); event.accepted = true; return }
    if (event.key === Qt.Key_Right) { audio.cycleSink(1); event.accepted = true; return }
    if (event.key === Qt.Key_Up) { keyboardRow = Math.max(0, keyboardRow - 1); event.accepted = true; return }
    if (event.key === Qt.Key_Down) { keyboardRow = Math.min(6, keyboardRow + 1); event.accepted = true; return }
    if (event.text === "k") { audio.setLeft(audio.left + 0.05); event.accepted = true; return }
    if (event.text === "j") { audio.setLeft(audio.left - 0.05); event.accepted = true; return }
    if (event.text === "K") { audio.setRight(audio.right + 0.05); event.accepted = true; return }
    if (event.text === "J") { audio.setRight(audio.right - 0.05); event.accepted = true; return }
    if (event.text === "h") { audio.shiftBalance(-0.03); event.accepted = true; return }
    if (event.text === "l") { audio.shiftBalance(0.03); event.accepted = true; return }
    if (event.text === "L" || event.text === "c") { audio.toggleLock(); event.accepted = true; return }
    if (event.text === "m") { audio.toggleMute(); event.accepted = true; return }
    if (event.text === "r") { audio.reset(); event.accepted = true; return }
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
      if (keyboardRow === 0) sinkPicker.open()
      else if (keyboardRow === 4) audio.toggleLock()
      else if (keyboardRow === 5) audio.toggleMute()
      else if (keyboardRow === 6) audio.reset()
      event.accepted = true
    }
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
    contentWidth: fittedContentWidth(420)
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
          meta: audio.muted ? "Output muted" : "Independent stereo control"
          detail: audio.channelsLocked ? "L = R" : Model.balanceLabel(audio.balance)
          foreground: root.foreground
          fontFamily: bar ? bar.fontFamily : Style.font.family
          iconComponent: Component { Text { text: root.icon(); color: root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.display } }
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

        Column {
          width: parent.width
          spacing: Style.spacing.xs
          PanelSectionHeader { text: "OUTPUT"; foreground: root.foreground; fontFamily: bar ? bar.fontFamily : Style.font.family }
          Row {
            width: parent.width
            spacing: Style.spacing.xs
            PanelActionButton { iconText: "󰅁"; tooltipText: "Previous output · Left / Shift+Tab"; foreground: root.foreground; enabled: audio.sinks.length > 1; onClicked: audio.cycleSink(-1) }
            Dropdown {
              id: sinkPicker
              width: parent.width - parent.spacing * 2 - Style.space(44)
              showLabel: false
              value: audio.sinkName
              options: audio.sinkOptions
              hasCursor: root.keyboardRow === 0
              foreground: root.foreground
              fontFamily: bar ? bar.fontFamily : Style.font.family
              onChanged: function(value) { audio.selectSink(value) }
            }
            PanelActionButton { iconText: "󰅂"; tooltipText: "Next output · Right / Tab"; foreground: root.foreground; enabled: audio.sinks.length > 1; onClicked: audio.cycleSink(1) }
          }
          Text { width: parent.width; text: root.sinkPosition + " of " + audio.sinks.length; color: root.subtle; horizontalAlignment: Text.AlignHCenter; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.sm
          PanelSectionHeader { text: "CHANNELS"; foreground: root.foreground; fontFamily: bar ? bar.fontFamily : Style.font.family }
          ChannelSlider { width: parent.width; label: "LEFT"; hint: "J / K"; value: audio.left; enabled: audio.stereoSupported; selected: root.keyboardRow === 1; onMoved: function(value) { audio.setLeft(value) } }
          ChannelSlider { width: parent.width; label: "RIGHT"; hint: "Shift+J / K"; value: audio.right; enabled: audio.stereoSupported; selected: root.keyboardRow === 2; onMoved: function(value) { audio.setRight(value) } }
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xs
          Row {
            width: parent.width
            Text { text: "BALANCE  ·  H / L"; color: root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
            Text { width: parent.width - x; horizontalAlignment: Text.AlignRight; text: Model.balanceLabel(audio.balance); color: Math.abs(audio.balance) < 0.005 ? Color.accent : root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
          }
          PanelSlider { width: parent.width; value: audio.balance; minimum: -1; maximum: 1; step: 0.05; tickCount: 3; enabled: audio.stereoSupported; onMoved: function(value) { audio.setBalance(value) } }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.sm
          Button { width: (parent.width - parent.spacing * 2) / 3; text: audio.channelsLocked ? "Locked" : "Unlocked"; iconText: audio.channelsLocked ? "󰌷" : "󰌸"; tooltipText: "L · Lock channels to equal volume"; selected: root.keyboardRow === 4; active: audio.channelsLocked; focusable: true; onClicked: audio.toggleLock() }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: audio.muted ? "Unmute" : "Mute"; iconText: audio.muted ? "󰕾" : "󰝟"; selected: root.keyboardRow === 5; focusable: true; onClicked: audio.toggleMute() }
          Button { width: (parent.width - parent.spacing * 2) / 3; text: "Reset"; iconText: "󰑐"; selected: root.keyboardRow === 6; focusable: true; onClicked: audio.reset() }
        }

        Rectangle {
          width: parent.width
          height: shortcuts.implicitHeight + Style.spacing.md * 2
          radius: Style.cornerRadius
          color: Style.hoverFillFor(root.foreground, Color.accent)
          Grid {
            id: shortcuts
            anchors.centerIn: parent
            columns: 2
            columnSpacing: Style.space(24)
            rowSpacing: Style.spacing.xs
            Shortcut { keys: "J / K"; action: "Left − / +" }
            Shortcut { keys: "⇧J / K"; action: "Right − / +" }
            Shortcut { keys: "H / L"; action: "Balance" }
            Shortcut { keys: "← / →"; action: "Output" }
            Shortcut { keys: "L"; action: "Lock L = R" }
            Shortcut { keys: "M · R · Q"; action: "Mute · Reset · Close" }
          }
        }
      }
    }
  }

  component ChannelSlider: Column {
    id: channel
    property string label: ""
    property string hint: ""
    property real value: 0
    property bool selected: false
    signal moved(real value)
    spacing: Style.spacing.xs
    opacity: enabled ? 1 : 0.45
    Row {
      width: parent.width
      Text { text: channel.label + (channel.hint !== "" ? "  ·  " + channel.hint : ""); color: channel.selected ? root.foreground : root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
      Text { width: parent.width - x; horizontalAlignment: Text.AlignRight; text: Model.percent(channel.value); color: channel.value > 1 ? root.danger : root.foreground; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: channel.value > 1 }
    }
    PanelSlider { width: parent.width; value: channel.value; minimum: 0; maximum: 1.5; step: 0.05; tickCount: 4; fillColor: channel.value > 1 ? root.danger : root.foreground; onMoved: function(value) { channel.moved(value) } }
  }

  component Shortcut: Row {
    property string keys: ""
    property string action: ""
    spacing: Style.spacing.sm
    Text { width: Style.space(54); text: parent.keys; color: Color.accent; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption; font.bold: true }
    Text { text: parent.action; color: root.subtle; font.family: bar ? bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption }
  }
}
