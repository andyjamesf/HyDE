import QtQuick
import qs.services

// Toggle rápido do centro de controlo: ícone, nome e estado. Clique liga/desliga; a seta
// (se `expandable`) abre a página de detalhe.
Rectangle {
    id: root

    property string icon
    property string label
    property string subtitle
    property bool checked: false
    property bool expandable: false

    signal toggled
    signal expand

    implicitHeight: 56
    radius: height / 2
    color: checked ? Theme.primary : Theme.surfaceContainerHigh

    Behavior on color {
        ColorAnim {}
    }

    StateLayer {
        anchors.fill: parent
        radius: root.radius
        highlight: Theme.alpha(root.checked ? Theme.onPrimary : Theme.text, 0.08)
        onClicked: root.toggled()
    }

    MaterialIcon {
        id: iconItem
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        size: 22
        fill: root.checked ? 1 : 0
        color: root.checked ? Theme.onPrimary : Theme.text
    }

    Column {
        anchors.left: iconItem.right
        anchors.leftMargin: 12
        anchors.right: chevron.visible ? chevron.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        StyledText {
            width: parent.width
            text: root.label
            font.weight: Font.DemiBold
            color: root.checked ? Theme.onPrimary : Theme.text
        }

        StyledText {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            font.pixelSize: 11
            color: root.checked ? Theme.alpha(Theme.onPrimary, 0.8) : Theme.textDim
        }
    }

    IconButton {
        id: chevron
        visible: root.expandable
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        size: 36
        icon: "chevron_right"
        color: root.checked ? Theme.onPrimary : Theme.text
        onClicked: root.expand()
    }
}
