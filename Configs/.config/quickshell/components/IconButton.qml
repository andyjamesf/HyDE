import QtQuick
import qs.services

// Botão redondo só com ícone. `checked` preenche-o com a cor primária (para toggles).
Item {
    id: root

    property string icon
    property bool checked: false
    property int size: 34
    property int iconSize: Math.round(size * 0.55)
    property color color: checked ? Theme.onPrimary : Theme.text
    property color background: checked ? Theme.primary : "transparent"
    property string tooltip
    property bool enabled: true

    signal clicked

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.background

        Behavior on color {
            ColorAnim {}
        }
    }

    StateLayer {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }

    MaterialIcon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        fill: root.checked ? 1 : 0
        color: root.color
    }
}
