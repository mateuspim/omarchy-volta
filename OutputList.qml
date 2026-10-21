import QtQuick
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "Model.js" as Model

// The output picker: one row per output with a device icon, its name, how it
// is attached, and an accent bar and check on the default. Up to four rows
// show inline; above that a window around the default plus "+N more", and an
// expanded list scrolls past six rows. The whole list is one keyboard row
// (Left/Right cycle outputs, Enter expands); the wheel over it cycles too.
Item {
  id: list
  property var entries: []
  property bool expanded: false
  property bool selected: false
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  signal chosen(string id)
  signal cycled(int delta)
  signal expandToggled()

  readonly property var view: Model.visibleOutputs(entries, expanded)
  readonly property real padding: Style.spacing.lg
  readonly property int rowHeight: Style.space(38)
  readonly property int maxRows: 6
  readonly property color dim: Qt.darker(foreground, 1.4)
  property real wheelAccumulator: 0

  implicitWidth: Style.space(320)
  implicitHeight: content.implicitHeight + padding * 2

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: list.selected ? Style.hoverFillFor(list.foreground, Commons.Color.accent) : "transparent"
    border.width: list.selected ? Math.max(1, Style.hoverBorderWidth) : 0
    border.color: Style.hoverBorderFor(list.foreground, Commons.Color.accent)
    Behavior on color { ColorAnimation { duration: 120 } }
  }

  // Wheel events the rows ignore bubble up to here; a scrollable expanded
  // list keeps the wheel for scrolling instead.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: function(wheel) {
      if (flick.interactive) { wheel.accepted = false; return }
      list.wheelAccumulator += wheel.angleDelta.y
      while (Math.abs(list.wheelAccumulator) >= 120) {
        var direction = list.wheelAccumulator > 0 ? 1 : -1
        list.cycled(-direction)
        list.wheelAccumulator -= direction * 120
      }
    }

    Column {
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: list.padding
      spacing: Style.spacing.sm

      Item {
        width: parent.width
        height: Math.max(header.implicitHeight, hints.implicitHeight)
        Text {
          id: header
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: "OUTPUT"
          color: list.selected ? list.foreground : list.dim
          font.family: list.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
        }
        KeyHints {
          id: hints
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          keys: ["←", "→"]
          lit: list.selected
          foreground: list.foreground
          fontFamily: list.fontFamily
        }
      }

      Flickable {
        id: flick
        width: parent.width
        height: Math.min(rows.implicitHeight, list.maxRows * list.rowHeight + (list.maxRows - 1) * rows.spacing)
        contentHeight: rows.implicitHeight
        interactive: contentHeight > height
        clip: interactive
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: rows
          width: flick.width
          spacing: Style.spacing.xs
          Repeater {
            model: list.view.rows
            OutputRow {}
          }
        }
      }

      Item {
        width: parent.width
        height: Math.max(0, list.rowHeight - Style.space(16))
        visible: list.view.overflow
        Button {
          anchors.fill: parent
          leftAlign: true
          text: list.expanded ? "Show fewer" : "+" + list.view.hidden + " more"
          iconText: list.expanded ? "󰅃" : "󰅀"
          fontSize: Style.font.bodySmall
          foreground: list.dim
          fontFamily: list.fontFamily
          Accessible.role: Accessible.Button
          Accessible.name: list.expanded ? "Show fewer outputs" : "Show all outputs"
          onClicked: list.expandToggled()
        }
      }
    }
  }

  component OutputRow: Rectangle {
    id: row
    required property var modelData
    width: rows.width
    height: list.rowHeight
    radius: Style.cornerRadius
    color: modelData.active ? Style.selectedFillFor(list.foreground, Commons.Color.accent)
      : (rowMouse.containsMouse ? Style.hoverFillFor(list.foreground, Commons.Color.accent) : "transparent")
    Accessible.role: Accessible.RadioButton
    Accessible.name: modelData.label
    Accessible.description: modelData.subtitle
    Accessible.checked: modelData.active
    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
      visible: row.modelData.active
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(2, Style.space(3))
      height: parent.height - Style.spacing.lg * 2
      radius: width / 2
      color: Commons.Color.accent
    }
    Text {
      id: glyph
      anchors.left: parent.left
      anchors.leftMargin: Style.spacing.xxl
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(22)
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: row.modelData.glyph
      color: row.modelData.active ? Commons.Color.accent : list.dim
      font.family: list.fontFamily
      font.pixelSize: Style.font.heading
    }
    Column {
      anchors.left: glyph.right
      anchors.leftMargin: Style.spacing.xl
      anchors.right: check.left
      anchors.rightMargin: Style.spacing.md
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.xxs
      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: row.modelData.label
        elide: Text.ElideRight
        color: list.foreground
        font.family: list.fontFamily
        font.pixelSize: Style.font.body
        font.bold: row.modelData.active
      }
      Text {
        width: parent.width
        visible: text !== ""
        textFormat: Text.PlainText
        text: row.modelData.subtitle
        elide: Text.ElideRight
        color: list.dim
        font.family: list.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
    Text {
      id: check
      anchors.right: parent.right
      anchors.rightMargin: Style.spacing.xl
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: row.modelData.active ? "󰄬" : ""
      color: Commons.Color.accent
      font.family: list.fontFamily
      font.pixelSize: Style.font.title
    }
    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (!row.modelData.active) list.chosen(row.modelData.id)
    }
  }
}
