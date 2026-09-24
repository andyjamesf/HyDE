pragma Singleton
import QtQuick
import Quickshell

// Durações e curvas de animação usadas em toda a shell (inspiradas no Material 3 "expressive").
// Usar sempre estas, para o movimento ser consistente; o config.json pode escalá-las ou desligá-las.
Singleton {
    readonly property real scale: Config.appearance.animationScale

    readonly property int fast: 150 * scale
    readonly property int normal: 250 * scale
    readonly property int slow: 400 * scale
    readonly property int spatial: 500 * scale

    // Curvas em formato BezierSpline (pontos de controlo + ponto final).
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
    readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    // Com ressalto ligeiro: para movimentos espaciais (indicadores, painéis a entrar).
    readonly property var expressive: [0.38, 1.21, 0.22, 1, 1, 1]
}
