import QtQuick
import qs.services

Text {
    color: Theme.text
    font.family: Config.appearance.font
    font.pixelSize: Config.appearance.fontSize
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnim {}
    }
}
