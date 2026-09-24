import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Cabeçalho de um painel: ícone, título e, opcionalmente, um switch à direita.
RowLayout {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool hasSwitch: false
    property bool checked: false
    default property alias extra: extraRow.data

    signal toggled

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        implicitWidth: 38
        implicitHeight: 38
        radius: 19
        color: root.hasSwitch && !root.checked ? Theme.surfaceContainerHighest : Theme.primaryContainer

        MaterialIcon {
            anchors.centerIn: parent
            icon: root.icon
            size: 20
            fill: 1
            color: root.hasSwitch && !root.checked ? Theme.textDim : Theme.onPrimaryContainer
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        StyledText {
            visible: root.subtitle !== ""
            Layout.fillWidth: true
            text: root.subtitle
            font.pixelSize: 11
            color: Theme.textDim
        }
    }

    Row {
        id: extraRow
        spacing: 4
    }

    StyledSwitch {
        visible: root.hasSwitch
        checked: root.checked
        onToggled: root.toggled()
    }
}
