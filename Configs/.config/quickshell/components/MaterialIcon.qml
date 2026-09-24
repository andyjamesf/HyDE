import QtQuick
import qs.services

// Ícone Material Symbols por nome (ligadura), ex.: MaterialIcon { icon: "volume_up" }.
// `fill` (0..1) anima o preenchimento através do eixo variável FILL da fonte.
Text {
    id: root

    property string icon
    property real fill: 0
    property int weight: 400
    property int size: Config.appearance.iconSize

    text: icon
    color: Theme.text
    font.family: Config.appearance.iconFont
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": root.fill,
            "wght": root.weight,
            "opsz": Math.max(20, Math.min(48, root.size))
        })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    Behavior on fill {
        NumberAnim {}
    }
    Behavior on color {
        ColorAnim {}
    }
}
