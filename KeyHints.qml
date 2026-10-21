import QtQuick
import qs.Commons
import qs.Commons as Commons

// A shortcut: its keycaps, then an optional short label ("mute").
Row {
  id: hint
  property var keys: []
  property string label: ""
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  property bool lit: false

  spacing: Style.spacing.xs

  Repeater {
    model: hint.keys
    KeyCap {
      required property string modelData
      key: modelData
      lit: hint.lit
      foreground: hint.foreground
      fontFamily: hint.fontFamily
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Text {
    visible: hint.label !== ""
    textFormat: Text.PlainText
    leftPadding: Style.spacing.xxs
    text: hint.label
    color: Qt.darker(hint.foreground, 1.4)
    font.family: hint.fontFamily
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
  }
}
