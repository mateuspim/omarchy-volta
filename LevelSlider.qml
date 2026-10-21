import QtQuick
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "Model.js" as Model

// One keyboard row of the popup: a label with its keys and value, over a
// slider. Volume rows draw a two-tone fill and a tinted over-gain zone past
// 100 %; the balance row fills out of a centre detent toward the louder side.
// Omarchy's PanelSlider still owns the knob, drag, wheel and notches; its own
// track and fill are made transparent and drawn here instead.
Item {
  id: level
  property QtObject bar: null
  property string label: ""
  property var keys: []
  property string valueText: ""
  property real value: 0
  property real minimum: 0
  property real maximum: Model.MAX_VOLUME
  property real step: 0.05
  property bool centred: false
  property bool selected: false
  property color foreground: Commons.Color.foreground
  property color danger: Commons.Color.urgent
  property string fontFamily: Style.font.family
  signal moved(real value)

  readonly property real padding: Style.spacing.lg
  readonly property bool overGain: !centred && Model.isOverGain(slider.liveValue)
  readonly property var split: Model.gainSplit(slider.liveValue)
  readonly property var span: Model.balanceSpan(slider.liveValue)
  readonly property color fillColor: selected ? Commons.Color.accent : foreground

  implicitWidth: Style.space(320)
  implicitHeight: content.implicitHeight + padding * 2
  opacity: enabled ? 1 : 0.45

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: level.selected ? Style.hoverFillFor(level.foreground, Commons.Color.accent) : "transparent"
    border.width: level.selected ? Math.max(1, Style.hoverBorderWidth) : 0
    border.color: Style.hoverBorderFor(level.foreground, Commons.Color.accent)
    Behavior on color { ColorAnimation { duration: 120 } }
  }

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: level.padding
    spacing: Style.spacing.sm

    Item {
      width: parent.width
      height: Math.max(labelText.implicitHeight, hints.implicitHeight, valueLabel.implicitHeight)

      Text {
        id: labelText
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: level.label
        color: level.selected ? level.foreground : Qt.darker(level.foreground, 1.4)
        font.family: level.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
      }
      Text {
        id: valueLabel
        anchors.left: labelText.right
        anchors.leftMargin: Style.spacing.lg
        anchors.verticalCenter: parent.verticalCenter
        visible: level.valueText !== ""
        textFormat: Text.PlainText
        text: level.valueText
        color: level.overGain ? level.danger : level.foreground
        font.family: level.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
      KeyHints {
        id: hints
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        keys: level.keys
        lit: level.selected
        foreground: level.foreground
        fontFamily: level.fontFamily
      }
    }

    Item {
      width: parent.width
      height: slider.implicitHeight

      Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: slider.trackHeight
        radius: height / 2
        color: Style.selectedFillFor(level.foreground, Commons.Color.accent)
      }
      Rectangle {
        visible: !level.centred
        anchors.verticalCenter: track.verticalCenter
        x: track.width * Model.UNITY_FRACTION
        width: track.width - x
        height: track.height
        radius: track.radius
        color: Util.alpha(level.danger, 0.28)
      }
      Rectangle {
        anchors.verticalCenter: track.verticalCenter
        x: level.centred ? track.width * level.span.from : 0
        width: track.width * (level.centred ? level.span.to - level.span.from : level.split.normal)
        height: track.height
        radius: track.radius
        color: level.fillColor
      }
      Rectangle {
        visible: level.overGain
        anchors.verticalCenter: track.verticalCenter
        x: track.width * level.split.normal
        width: track.width * level.split.over
        height: track.height
        radius: track.radius
        color: level.danger
      }
      PanelSlider {
        id: slider
        anchors.fill: parent
        bar: level.bar
        value: level.value
        minimum: level.minimum
        maximum: level.maximum
        step: level.step
        trackHeight: Math.max(6, Math.round(Style.spacing.controlHeight * 0.2))
        trackColor: "transparent"
        fillColor: "transparent"
        knobColor: level.overGain ? level.danger : level.fillColor
        tickCount: level.centred ? 3 : 4
        tickColor: Commons.Color.popups.background
        onMoved: function(next) { level.moved(next) }
      }
    }
  }
}
