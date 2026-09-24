import QtQuick
import qs.services

// Área clicável com a camada de hover/pressão por baixo do conteúdo. Emite os mesmos sinais para
// os três botões e acumula o scroll (touchpads mandam muitos eventos pequenos) em passos de 120.
MouseArea {
    id: root

    property real radius: height / 2
    property color highlight: Theme.hover
    property bool active: false

    signal scrolled(int direction) // +1 para cima, -1 para baixo

    property real _wheel: 0

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor

    onWheel: wheel => {
        _wheel += wheel.angleDelta.y;
        while (_wheel >= 120) {
            _wheel -= 120;
            scrolled(1);
        }
        while (_wheel <= -120) {
            _wheel += 120;
            scrolled(-1);
        }
    }

    Rectangle {
        anchors.fill: parent
        z: -1
        radius: root.radius
        color: root.pressed ? Theme.pressed : root.highlight
        opacity: root.containsMouse || root.active ? 1 : 0

        Behavior on opacity {
            NumberAnim {
                duration: Anim.fast
            }
        }
    }
}
