import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Wi-Fi: ligar/desligar, redes visíveis e ligação. As redes protegidas desconhecidas pedem a
// palavra-passe; o campo só aparece onde há teclado (`canType`, no centro de controlo). Na popup
// da barra, escolher uma dessas redes abre o centro de controlo nesta página.
ColumnLayout {
    id: root
    // No centro de controlo: o cabeçalho leva o botão de voltar.
    property bool backButton: false
    signal back

    property bool canType: false

    width: 320
    spacing: 8

    Component.onCompleted: Network.scanUsers++
    Component.onDestruction: Network.scanUsers--

    PanelHeader {
        backButton: root.backButton
        onBack: root.back()
        icon: Network.wired ? "lan" : Network.icon
        title: "Wi-Fi"
        subtitle: Network.wired ? "Wired connection" : Network.activeWifi ? `Connected to ${Network.name}` : Network.wifiEnabled ? "Not connected" : "Desligado"
        hasSwitch: true
        checked: Network.wifiEnabled
        onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
    }

    StyledText {
        visible: Network.lastError !== ""
        Layout.fillWidth: true
        text: Network.lastError
        color: Theme.error
        font.pixelSize: Theme.labelSmall
        wrapMode: Text.WordWrap
    }

    // Palavra-passe para a rede escolhida.
    Card {
        visible: root.canType && Network.pendingNetwork !== null
        Layout.fillWidth: true
        color: Theme.surfaceContainerHighest
        padding: 12

        ColumnLayout {
            width: parent.width
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: `Password for ${Network.pendingNetwork?.name ?? ""}`
                font.weight: Font.DemiBold
            }

            StyledTextField {
                id: password
                Layout.fillWidth: true
                icon: "key"
                placeholder: "Password"
                echoMode: TextInput.Password
                onAccepted: connect.clicked()
                onVisibleChanged: if (visible) {
                    text = "";
                    focusInput();
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight

                IconButton {
                    icon: "close"
                    size: 34
                    onClicked: Network.pendingNetwork = null
                }

                IconButton {
                    id: connect
                    icon: "arrow_forward"
                    size: 34
                    checked: true
                    enabled: password.text.length >= 8
                    onClicked: Network.connectWithPassword(password.text)
                }
            }
        }
    }

    Flickable {
        visible: Network.wifiEnabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width

            Repeater {
                model: Network.networks

                ListRow {
                    required property var modelData
                    width: list.width
                    icon: Network.signalIcon(modelData.signalStrength)
                    iconFill: 1
                    title: modelData.name
                    subtitle: modelData.connected ? "Ligado" : modelData.stateChanging ? "A ligar…" : modelData.known ? "Guardada" : Network.isSecure(modelData) ? "Secured" : "Open"
                    highlighted: modelData.connected
                    busy: modelData.stateChanging
                    onClicked: {
                        Network.activate(modelData);
                        if (Network.pendingNetwork && !root.canType)
                            ShellState.openControlCenter("wifi");
                    }

                    MaterialIcon {
                        visible: Network.isSecure(modelData) && !modelData.connected
                        icon: "lock"
                        size: 16
                        color: Theme.textFaint
                    }

                    IconButton {
                        visible: modelData.known && !modelData.connected
                        icon: "delete"
                        size: 28
                        color: Theme.textDim
                        onClicked: modelData.forget()
                    }
                }
            }
        }
    }

    StyledText {
        visible: Network.wifiEnabled && Network.networks.length === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Searching for networks…"
        color: Theme.textDim
        padding: 8
    }

    ListRow {
        Layout.fillWidth: true
        icon: "settings"
        title: "Network settings"
        onClicked: Utils.run("nm-connection-editor")
    }
}
