import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.components
import qs.services
import qs.modules.controls
import qs.modules.notifications

// Centro de controlo: painel lateral com toggles rápidos, sliders, media, atalhos do HyDE e
// páginas de detalhe (Wi-Fi, Bluetooth, som). Abre no ecrã com foco; fecha com Esc ou ao
// clicar fora. `qs ipc call controlcenter toggle`.
PanelWindow {
    id: panel

    required property ShellScreen modelData
    readonly property bool open: ShellState.controlCenterOpen && (ShellState.controlCenterScreen === "" || ShellState.controlCenterScreen === modelData.name)
    // 0 = aberto, 1 = fechado (fora do ecrã).
    property real slide: open ? 0 : 1

    Behavior on slide {
        NumberAnim {
            duration: Anim.normal
            easing.bezierCurve: panel.open ? Anim.emphasized : Anim.standardAccel
        }
    }

    // A janela fica sempre criada (criar uma layer surface a cada abertura atrasava o painel);
    // fechada, não tem conteúdo à vista e a máscara vazia deixa passar os cliques.
    screen: modelData
    visible: true
    mask: Region {
        item: panel.open || panel.slide < 1 ? bg : null
    }
    anchors {
        top: BarLayout.atTop
        bottom: !BarLayout.atTop
        right: true
    }
    margins {
        top: BarLayout.atTop ? 6 : 0
        bottom: BarLayout.atTop ? 0 : 6
        right: 6
    }
    implicitWidth: 400
    implicitHeight: Math.min(content.implicitHeight + 32, modelData.height - BarLayout.height - BarLayout.margin - 24)
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "quickshell:controlcenter"
    WlrLayershell.layer: WlrLayer.Top
    // Teclado só a pedido: para escrever a palavra-passe do Wi-Fi e para o Esc.
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: if (open) {
        SysInfo.refresh();
        NightLight.refresh();
    }

    HyprlandFocusGrab {
        windows: [panel]
        active: panel.open
        onCleared: ShellState.closeControlCenter()
    }

    Rectangle {
        id: bg

        width: parent.width
        height: parent.height
        x: panel.slide * (panel.width + 12)
        opacity: 1 - panel.slide * 0.6
        radius: BarLayout.hyprRounding + 12
        color: Theme.alpha(Theme.surface, 0.94)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.8)
        focus: panel.open
        Keys.onEscapePressed: ShellState.controlCenterPage !== "" ? ShellState.controlCenterPage = "" : ShellState.closeControlCenter()

        Flickable {
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 14

                Header {}

                Loader {
                    id: page
                    Layout.fillWidth: true
                    sourceComponent: ({
                            "wifi": wifiPage,
                            "bluetooth": bluetoothPage,
                            "audio": audioPage,
                            "notifications": notificationsPage
                        })[ShellState.controlCenterPage] ?? mainPage

                    // Troca de página: o conteúdo novo entra com um deslize curto.
                    onLoaded: {
                        item.opacity = 0;
                        item.x = ShellState.controlCenterPage === "" ? -16 : 16;
                        pageIn.restart();
                    }

                    ParallelAnimation {
                        id: pageIn
                        NumberAnimation {
                            target: page.item
                            property: "opacity"
                            to: 1
                            duration: Anim.normal
                        }
                        NumberAnimation {
                            target: page.item
                            property: "x"
                            to: 0
                            duration: Anim.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.emphasized
                        }
                    }
                }
            }
        }
    }

    component Header: RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ClippingRectangle {
            implicitWidth: 46
            implicitHeight: 46
            radius: 23
            color: Theme.primaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                icon: "person"
                size: 26
                fill: 1
                color: Theme.onPrimaryContainer
            }

            Image {
                id: avatar
                anchors.fill: parent
                source: SysInfo.avatar
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 92
                sourceSize.height: 92
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: `${SysInfo.user}@${SysInfo.host}`
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: `Ligado há ${SysInfo.uptime}`
                font.pixelSize: 11
                color: Theme.textDim
            }
        }

        IconButton {
            icon: "settings"
            size: 36
            onClicked: {
                ShellState.closeControlCenter();
                Utils.run(`xdg-open ${Quickshell.shellPath("config/config.json")}`);
            }
        }

        IconButton {
            icon: "lock"
            size: 36
            onClicked: {
                ShellState.closeControlCenter();
                Utils.run("loginctl lock-session");
            }
        }

        IconButton {
            icon: "power_settings_new"
            size: 36
            background: Theme.alpha(Theme.error, 0.18)
            color: Theme.error
            onClicked: {
                ShellState.togglePowerMenu();
            }
        }
    }

    component DetailPage: ColumnLayout {
        id: detail

        property string title
        default property alias body: bodyHolder.data

        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            IconButton {
                icon: "arrow_back"
                size: 36
                onClicked: ShellState.controlCenterPage = ""
            }

            StyledText {
                Layout.fillWidth: true
                text: detail.title
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            id: bodyHolder
            Layout.fillWidth: true
        }
    }

    Component {
        id: wifiPage

        DetailPage {
            title: "Rede"

            WifiPanel {
                Layout.fillWidth: true
                canType: true
            }
        }
    }

    Component {
        id: bluetoothPage

        DetailPage {
            title: "Bluetooth"

            BluetoothPanel {
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: notificationsPage

        DetailPage {
            title: "Notificações"

            NotificationList {
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: audioPage

        DetailPage {
            title: "Som"

            AudioPanel {
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: mainPage

        ColumnLayout {
            spacing: 14

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                QuickToggle {
                    Layout.fillWidth: true
                    icon: Network.wired ? "lan" : Network.icon
                    label: "Wi-Fi"
                    subtitle: Network.wired ? "Cabo" : Network.activeWifi ? Network.name : Network.wifiEnabled ? "Sem ligação" : "Desligado"
                    checked: Network.wifiEnabled
                    expandable: true
                    onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
                    onExpand: ShellState.controlCenterPage = "wifi"
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: Bluetooth.available
                    icon: Bluetooth.icon
                    label: "Bluetooth"
                    subtitle: Bluetooth.summary
                    checked: Bluetooth.enabled
                    expandable: true
                    onToggled: Bluetooth.setEnabled(!Bluetooth.enabled)
                    onExpand: ShellState.controlCenterPage = "bluetooth"
                }

                QuickToggle {
                    Layout.fillWidth: true
                    icon: Notifs.dnd ? "notifications_off" : "notifications"
                    label: "Não incomodar"
                    subtitle: Notifs.dnd ? "Ligado" : `${Notifs.count} notificações`
                    checked: Notifs.dnd
                    onToggled: Notifs.toggleDnd()
                }

                QuickToggle {
                    Layout.fillWidth: true
                    icon: "nightlight"
                    label: "Luz noturna"
                    subtitle: NightLight.active ? "Ligada" : "Desligada"
                    checked: NightLight.active
                    onToggled: NightLight.toggle()
                }

                QuickToggle {
                    Layout.fillWidth: true
                    visible: Battery.available || PowerProfiles.profile !== undefined
                    icon: Battery.profileIcon
                    label: "Energia"
                    subtitle: Battery.profileName
                    checked: Battery.profile !== 1
                    onToggled: Battery.setProfile((Battery.profile + 1) % (PowerProfiles.hasPerformanceProfile ? 3 : 2))
                }

                QuickToggle {
                    Layout.fillWidth: true
                    icon: "coffee"
                    label: "Cafeína"
                    subtitle: ShellState.idleInhibited ? "Sem suspensão" : "Desligada"
                    checked: ShellState.idleInhibited
                    onToggled: ShellState.idleInhibited = !ShellState.idleInhibited
                }

                QuickToggle {
                    Layout.fillWidth: true
                    icon: Audio.micIcon
                    label: "Microfone"
                    subtitle: Audio.micMuted ? "Silenciado" : "Ativo"
                    checked: !Audio.micMuted
                    onToggled: Audio.toggleMicMute()
                }

                QuickToggle {
                    Layout.fillWidth: true
                    icon: "wallpaper"
                    label: "Cores do wallpaper"
                    subtitle: Prefs.colorSource === "wallpaper" ? "Wallpaper" : "Tema do HyDE"
                    checked: Prefs.colorSource === "wallpaper"
                    onToggled: Theme.setColorSource(Prefs.colorSource === "wallpaper" ? "hyde" : "wallpaper")
                }
            }

            Card {
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        StyledSlider {
                            Layout.fillWidth: true
                            icon: Audio.icon
                            value: Audio.muted ? 0 : Audio.volume
                            onMoved: v => Audio.setVolume(v)
                            onIconClicked: Audio.toggleMute()
                        }

                        IconButton {
                            icon: "chevron_right"
                            size: 34
                            onClicked: ShellState.controlCenterPage = "audio"
                        }
                    }

                    StyledSlider {
                        Layout.fillWidth: true
                        Layout.rightMargin: 38
                        icon: Audio.micIcon
                        value: Audio.micMuted ? 0 : Audio.micVolume
                        onMoved: v => Audio.setMicVolume(v)
                        onIconClicked: Audio.toggleMicMute()
                    }

                    StyledSlider {
                        Layout.fillWidth: true
                        Layout.rightMargin: 38
                        visible: Brightness.available
                        icon: Brightness.icon
                        value: Brightness.percent / 100
                        onMoved: v => Brightness.set(v * 100)
                    }
                }
            }

            Card {
                visible: Media.active !== null
                Layout.fillWidth: true

                MediaCard {
                    width: parent.width
                }
            }

            NotificationList {
                Layout.fillWidth: true
                limit: 3
            }

            ListRow {
                visible: Notifs.count > 3
                Layout.fillWidth: true
                icon: "expand_more"
                title: `Ver todas (${Notifs.count})`
                onClicked: ShellState.controlCenterPage = "notifications"
            }

            SectionLabel {
                text: "HyDE"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: [
                        {
                            icon: "skip_next",
                            label: "Wallpaper",
                            cmd: "hyde-shell app -t scope -- wallpaper.sh --next --global"
                        },
                        {
                            icon: "image",
                            label: "Escolher",
                            cmd: "hyde-shell app -t scope -- wallpaper.sh --select --global"
                        },
                        {
                            icon: "palette",
                            label: "Tema",
                            cmd: "hyde-shell app -t scope -- theme.select.sh"
                        },
                        {
                            icon: "view_quilt",
                            label: "Layout",
                            action: () => BarLayout.cycle(1)
                        },
                        {
                            icon: "animation",
                            label: "Animações",
                            cmd: "hyde-shell animations --select"
                        },
                        {
                            icon: "keyboard",
                            label: "Atalhos",
                            cmd: "hyde-shell keybinds_hint"
                        }
                    ]

                    Rectangle {
                        id: tile

                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 64
                        radius: 18
                        color: Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                icon: tile.modelData.icon
                                size: 22
                                color: Theme.primary
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.label
                                font.pixelSize: 11
                            }
                        }

                        StateLayer {
                            anchors.fill: parent
                            radius: tile.radius
                            onClicked: {
                                if (tile.modelData.action) {
                                    tile.modelData.action();
                                } else {
                                    ShellState.closeControlCenter();
                                    Utils.run(tile.modelData.cmd);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
