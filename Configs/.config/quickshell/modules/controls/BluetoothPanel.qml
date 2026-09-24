import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth as QsBluetooth
import qs.components
import qs.services

// Bluetooth: ligar/desligar, dispositivos emparelhados (ligar/desligar/esquecer) e pesquisa de
// dispositivos novos para emparelhar.
ColumnLayout {
    id: root
    // No centro de controlo: o cabeçalho leva o botão de voltar.
    property bool backButton: false
    signal back

    width: 320
    spacing: 8

    // A pesquisa gasta bateria: pára quando o painel fecha.
    Component.onDestruction: Bluetooth.setScanning(false)

    PanelHeader {
        backButton: root.backButton
        onBack: root.back()
        icon: Bluetooth.icon
        title: "Bluetooth"
        subtitle: Bluetooth.summary
        hasSwitch: true
        checked: Bluetooth.enabled
        onToggled: Bluetooth.setEnabled(!Bluetooth.enabled)
    }

    SectionLabel {
        visible: Bluetooth.enabled && Bluetooth.paired.length > 0
        text: "Os meus dispositivos"
    }

    Repeater {
        model: Bluetooth.enabled ? Bluetooth.paired : []

        ListRow {
            required property var modelData
            Layout.fillWidth: true
            icon: Bluetooth.iconFor(modelData)
            iconFill: modelData.connected ? 1 : 0
            title: modelData.name
            subtitle: modelData.state === QsBluetooth.BluetoothDeviceState.Connecting ? "A ligar…" : modelData.connected ? "Ligado" + (modelData.batteryAvailable ? ` · ${Math.round(modelData.battery * 100)}% bateria` : "") : "Desligado"
            highlighted: modelData.connected
            busy: modelData.state === QsBluetooth.BluetoothDeviceState.Connecting || modelData.state === QsBluetooth.BluetoothDeviceState.Disconnecting
            onClicked: Bluetooth.activate(modelData)

            IconButton {
                visible: !modelData.connected
                icon: "delete"
                size: 28
                color: Theme.textDim
                onClicked: modelData.forget()
            }
        }
    }

    RowLayout {
        visible: Bluetooth.enabled
        Layout.fillWidth: true

        SectionLabel {
            text: Bluetooth.scanning ? "À procura…" : "Outros dispositivos"
        }

        IconButton {
            icon: Bluetooth.scanning ? "stop" : "search"
            size: 30
            checked: Bluetooth.scanning
            onClicked: Bluetooth.setScanning(!Bluetooth.scanning)
        }
    }

    Flickable {
        visible: Bluetooth.enabled && Bluetooth.discovered.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 240)
        contentHeight: found.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: found
            width: parent.width

            Repeater {
                model: Bluetooth.discovered

                ListRow {
                    required property var modelData
                    width: found.width
                    icon: Bluetooth.iconFor(modelData)
                    title: modelData.name
                    subtitle: modelData.pairing ? "A emparelhar…" : "Clique para emparelhar"
                    busy: modelData.pairing
                    onClicked: Bluetooth.activate(modelData)
                }
            }
        }
    }

    StyledText {
        visible: Bluetooth.enabled && !Bluetooth.scanning && Bluetooth.discovered.length === 0
        Layout.fillWidth: true
        text: "Toque na lupa para procurar dispositivos novos."
        font.pixelSize: Theme.labelSmall
        color: Theme.textFaint
        wrapMode: Text.WordWrap
    }

    ListRow {
        Layout.fillWidth: true
        icon: "settings"
        title: "Definições de Bluetooth"
        onClicked: Utils.run("blueman-manager")
    }
}
