import QtQuick
import qs.Ui
import qs.Commons

Panel {
  id: root

  moduleName: "pym.volta"
  ipcTarget: "pym.volta"

  implicitWidth: bar && bar.vertical ? bar.barSize : 34
  implicitHeight: bar && bar.vertical ? 34 : bar.barSize

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰕾"
    tooltipText: "Volta"
    onPressed: function(button) {
      if (button === Qt.LeftButton) root.toggle()
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: fittedContentWidth(360)
    contentHeight: fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: popup.contentWidth - popup.padding * 2
      spacing: 12

      Text {
        text: "Volta"
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : "monospace"
        font.pixelSize: 18
        font.bold: true
      }

      Text {
        width: parent.width
        text: "Per-channel volume and balance controls are coming next."
        color: bar ? bar.foreground : Color.foreground
        font.family: bar ? bar.fontFamily : "monospace"
        font.pixelSize: 13
        wrapMode: Text.WordWrap
        opacity: 0.75
      }
    }
  }
}
