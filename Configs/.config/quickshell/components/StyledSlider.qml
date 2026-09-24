import QtQuick
import qs.services

// Slider ao estilo Material 3 "expressive": trilho grosso com o ícone dentro, uma pega fina em pé
// que separa a parte ativa da inativa, e o valor à direita, fora do trilho.
// `value` vem de fora (0..1); ao arrastar, emite moved() e mostra o valor local para não saltar.
Item {
    id: root

    property real value: 0
    property string icon
    property bool enabled: true
    property bool showValue: true
    property real step: 0.05
    property color accent: Theme.primary

    signal moved(real value)
    signal iconClicked

    readonly property bool dragging: area.pressed
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : Math.max(0, Math.min(1, value))

    // Geometria: pega de 4 px com 4 px de folga de cada lado.
    property int trackHeight: 32
    readonly property int handleWidth: 4
    readonly property int gap: 4
    readonly property real trackWidth: track.width
    property real handleX: shown * (trackWidth - handleWidth)

    Behavior on handleX {
        enabled: !root.dragging
        NumberAnim {
            duration: Anim.fast
        }
    }

    implicitWidth: 240
    implicitHeight: trackHeight + 8
    opacity: enabled ? 1 : 0.45

    function setFromX(x) {
        dragValue = Math.max(0, Math.min(1, x / trackWidth));
        moved(dragValue);
    }

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: valueText.visible ? valueText.left : parent.right
        anchors.rightMargin: valueText.visible ? Theme.space3 : 0
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight

        // Parte ativa: redonda do lado de fora, quase reta junto à pega.
        Rectangle {
            visible: width > 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, root.handleX - root.gap)
            height: parent.height
            topLeftRadius: height / 2
            bottomLeftRadius: height / 2
            topRightRadius: Math.min(4, width / 2)
            bottomRightRadius: Math.min(4, width / 2)
            color: root.accent
        }

        Rectangle {
            readonly property real start: root.handleX + root.handleWidth + root.gap
            visible: width > 0
            x: start
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - start)
            height: parent.height
            topRightRadius: height / 2
            bottomRightRadius: height / 2
            topLeftRadius: Math.min(4, width / 2)
            bottomLeftRadius: Math.min(4, width / 2)
            color: Theme.surfaceContainerHighest
        }

        Rectangle {
            x: root.handleX
            anchors.verticalCenter: parent.verticalCenter
            width: root.handleWidth
            height: root.height
            radius: width / 2
            color: root.accent
        }

        MaterialIcon {
            visible: root.icon !== ""
            x: Theme.space3
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: Math.min(20, Math.round(root.trackHeight * 0.55))
            fill: 1
            color: root.handleX - root.gap > x + width ? Theme.onPrimary : Theme.textDim
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            enabled: root.enabled
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            onPressed: mouse => {
                // Clique no ícone: ação própria (normalmente silenciar), sem mexer no valor.
                if (root.icon !== "" && mouse.x < Theme.space3 + 24) {
                    mouse.accepted = false;
                    root.iconClicked();
                    return;
                }
                root.setFromX(mouse.x);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    root.setFromX(mouse.x);
            }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
        }
    }

    StyledText {
        id: valueText
        visible: root.showValue
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideNone
        text: `${Math.round(root.shown * 100)}%`
        font.pixelSize: Theme.labelLarge
        font.weight: Font.Medium
        color: Theme.textDim
    }
}
