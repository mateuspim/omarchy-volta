import QtQuick
import qs.Commons
import qs.Commons as Commons

// One key drawn as a small keycap, so shortcuts read as keys rather than as
// part of a label.
Rectangle {
  id: cap
  property string key: ""
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  property bool lit: false

  implicitWidth: Math.max(implicitHeight, keyText.implicitWidth + Style.spacing.md * 2)
  implicitHeight: keyText.implicitHeight + Style.spacing.xxs * 2
  radius: Math.max(2, Style.cornerRadius)
  color: lit ? Style.selectedFillFor(foreground, Commons.Color.accent) : Style.normalFillFor(foreground, Commons.Color.accent)
  border.width: Math.max(1, Style.normalBorderWidth)
  border.color: Style.normalBorderFor(foreground, Commons.Color.accent)

  Text {
    id: keyText
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: cap.key
    color: cap.lit ? cap.foreground : Qt.darker(cap.foreground, 1.25)
    font.family: cap.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
  }
}
