import QtQuick
import qs.services

// Slider grosso ao estilo Material 3 "expressive": a parte preenchida leva o ícone.
// `value` vem de fora (0..1); ao arrastar, emite moved() e mostra o valor local para não saltar.
Item {
    id: root

    property real value: 0
    property string icon
    property bool enabled: true
    property real step: 0.05
    property color accent: Theme.primary

    signal moved(real value)
    signal iconClicked

    readonly property bool dragging: area.pressed
    property real dragValue: 0
    readonly property real shown: dragging ? dragValue : Math.max(0, Math.min(1, value))

    implicitWidth: 240
    implicitHeight: 34
    opacity: enabled ? 1 : 0.45

    function setFromX(x) {
        dragValue = Math.max(0, Math.min(1, x / width));
        moved(dragValue);
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainerHighest
    }

    Rectangle {
        id: fill
        height: parent.height
        width: Math.max(height, root.shown * root.width)
        radius: height / 2
        color: root.accent

        Behavior on width {
            enabled: !root.dragging
            NumberAnim {
                duration: Anim.fast
            }
        }
    }

    MaterialIcon {
        id: iconItem
        visible: root.icon !== ""
        x: (root.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        size: Math.round(root.height * 0.55)
        fill: 1
        color: Theme.onPrimary
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: `${Math.round(root.shown * 100)}%`
        color: fill.width > root.width - 48 ? Theme.onPrimary : Theme.textDim
        font.pixelSize: 11
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onPressed: mouse => {
            // Clique no ícone: ação própria (normalmente silenciar), sem mexer no valor.
            if (root.icon !== "" && mouse.x < root.height) {
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
