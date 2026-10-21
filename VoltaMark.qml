import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons

// Volta's bar mark, tinted to the theme. The source image is white so one
// asset serves every theme and the muted/active states.
Item {
  id: mark
  property color tint: Commons.Color.foreground
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
