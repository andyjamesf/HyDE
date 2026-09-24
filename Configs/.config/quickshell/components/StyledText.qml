import QtQuick
import qs.services

// Texto da shell: Inter, algarismos tabulares (os números não "dançam" ao mudar) e uma folga
// vertical de 1 px, porque com `elide` o Qt recorta à caixa da linha e, com escala fracionária,
// as pernas das letras (g, p, y) ficavam cortadas.
Text {
    color: Theme.text
    font.family: Config.appearance.font
    font.pixelSize: Config.appearance.fontSize
    font.features: ({
            "tnum": 1
        })
    topPadding: 1
    bottomPadding: 1
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnim {}
    }
}
