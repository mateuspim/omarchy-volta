import QtQuick
import qs.Commons
import qs.Commons as Commons
import "Model.js" as Model

// The stereo picture at the top of the popup: both channel levels as large
// readouts over a meter that grows outward from the centre, one segment per
// 10 %. Segments step up in height toward the edges like the Volta mark, and
// the outer five sit in the over-gain zone, so imbalance and boost read at a
// glance before any number does (ADR 13).
Rectangle {
  id: stage
  property real leftLevel: 0
  property real rightLevel: 0
  property bool mono: false
  property bool muted: false
  property bool available: true
  property color foreground: Commons.Color.foreground
  property color danger: Commons.Color.urgent
  property string fontFamily: Style.font.family

  readonly property int segmentCount: 15
  readonly property color dim: Qt.darker(foreground, 1.4)

  implicitHeight: body.implicitHeight + Style.spacing.xxl * 2
  radius: Style.cornerRadius
  color: Style.normalFillFor(foreground, Commons.Color.accent)
  border.width: Math.max(1, Style.normalBorderWidth)
  border.color: Style.normalBorderFor(foreground, Commons.Color.accent)
  opacity: available ? 1 : 0.45

  Column {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.spacing.xxl
    spacing: Style.spacing.xl

    Item {
      width: parent.width
      height: leftReadout.implicitHeight

      Readout {
        id: leftReadout
        caption: stage.mono ? "VOLUME" : "LEFT"
        value: stage.leftLevel
        x: stage.mono ? (parent.width - width) / 2 : 0
        alignRight: false
        centred: stage.mono
      }
      Text {
        anchors.centerIn: parent
        visible: stage.muted && !stage.mono
        textFormat: Text.PlainText
        text: "󰝟  MUTED"
        color: stage.danger
        font.family: stage.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
      }
      Readout {
        visible: !stage.mono
        caption: "RIGHT"
        value: stage.rightLevel
        anchors.right: parent.right
        alignRight: true
      }
    }

    Row {
      id: meter
      width: parent.width
      height: Style.space(30)
      spacing: Style.spacing.lg
      opacity: stage.muted ? 0.4 : 1

      MeterHalf { width: (meter.width - meter.spacing * 2 - centre.width) / 2; value: stage.leftLevel; mirrored: true }
      Rectangle {
        id: centre
        width: Math.max(2, Style.space(2))
        height: meter.height
        radius: width / 2
        color: Commons.Color.accent
      }
      MeterHalf { width: (meter.width - meter.spacing * 2 - centre.width) / 2; value: stage.rightLevel; mirrored: false }
    }
  }

  component Readout: Item {
    id: readout
    property string caption: ""
    property real value: 0
    property bool alignRight: false
    property bool centred: false
    implicitWidth: Math.max(captionText.implicitWidth, valueText.implicitWidth)
    implicitHeight: captionText.implicitHeight + Style.spacing.xxs + valueText.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Text {
      id: captionText
      x: readout.centred ? (readout.width - width) / 2 : (readout.alignRight ? readout.width - width : 0)
      textFormat: Text.PlainText
      text: readout.caption
      color: stage.dim
      font.family: stage.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.2
    }
    Text {
      id: valueText
      y: captionText.implicitHeight + Style.spacing.xxs
      x: readout.centred ? (readout.width - width) / 2 : (readout.alignRight ? readout.width - width : 0)
      textFormat: Text.PlainText
      text: Model.percent(readout.value)
      color: Model.isOverGain(readout.value) ? stage.danger : stage.foreground
      font.family: stage.fontFamily
      font.pixelSize: Style.font.displayLarge
      font.bold: true
    }
  }

  component MeterHalf: Row {
    id: half
    property real value: 0
    property bool mirrored: false
    height: parent.height
    spacing: Math.max(2, Style.space(3))
    layoutDirection: mirrored ? Qt.RightToLeft : Qt.LeftToRight

    Repeater {
      model: stage.segmentCount
      Rectangle {
        required property int index
        readonly property string segment: Model.meterSegment(index, half.value)
        width: (half.width - half.spacing * (stage.segmentCount - 1)) / stage.segmentCount
        height: half.height * (0.3 + 0.7 * index / (stage.segmentCount - 1))
        anchors.bottom: parent.bottom
        radius: Math.min(width / 2, Math.max(1, Style.space(2)))
        color: segment === "lit" ? stage.foreground
          : segment === "over" ? stage.danger
          : segment === "zone" ? Util.alpha(stage.danger, 0.2)
          : Util.alpha(stage.foreground, 0.12)
        Behavior on color { ColorAnimation { duration: 120 } }
      }
    }
  }
}
