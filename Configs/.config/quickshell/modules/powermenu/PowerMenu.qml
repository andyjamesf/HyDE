import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.services

// Power menu compacto: um cartão ao centro com as ações de sessão. As ações que fecham tudo
// (sair, reiniciar, desligar) pedem um segundo clique/Enter para confirmar.
// Teclado: ←/→ escolher · Enter executar · Esc fechar · atalhos: B(loquear) S(uspender)
// H(ibernar) L(ogout/sair) R(einiciar) D(esligar).
PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property bool open: ShellState.powerMenuOpen && (ShellState.powerMenuScreen === "" || ShellState.powerMenuScreen === modelData.name)
    readonly property var actions: [
        {
            icon: "lock",
            label: "Bloquear",
            key: Qt.Key_B,
            cmd: "loginctl lock-session",
            confirm: false
        },
        {
            icon: "bedtime",
            label: "Suspender",
            key: Qt.Key_S,
            cmd: "systemctl suspend",
            confirm: false
        },
        {
            icon: "downloading",
            label: "Hibernar",
            key: Qt.Key_H,
            cmd: "systemctl hibernate",
            confirm: false
        },
        {
            icon: "logout",
            label: "Sair",
            key: Qt.Key_L,
            cmd: "hyprctl dispatch 'hl.dsp.exit()'",
            confirm: true
        },
        {
            icon: "restart_alt",
            label: "Reiniciar",
            key: Qt.Key_R,
            cmd: "systemctl reboot",
            confirm: true
        },
        {
            icon: "power_settings_new",
            label: "Desligar",
            key: Qt.Key_D,
            cmd: "systemctl poweroff",
            confirm: true
        }
    ]
    property int current: 0
    // A seleção só segue o rato quando ele se mexe (não quando o menu abre por baixo do cursor).
    property point lastMouse: Qt.point(-1, -1)
    // Ação à espera de confirmação (índice), ou -1.
    property int armed: -1

    screen: modelData
    visible: true
    implicitWidth: row.implicitWidth + 40
    implicitHeight: 170
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
        item: win.open ? card : null
    }

    WlrLayershell.namespace: "quickshell:powermenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // A grab só começa depois de a janela já estar aberta: com foco de teclado exclusivo,
    // ativá-la no mesmo instante fazia o Hyprland cancelá-la logo (e o menu fechava).
    property bool grabReady: false

    // Criado só quando abre (poupa memória): a preparação corre ao ser criado e ao reabrir.
    function init() {
        grabReady = false;
        if (open) {
            current = 0;
            armed = -1;
            lastMouse = Qt.point(-1, -1);
            focusTimer.restart();
        }
    }

    Component.onCompleted: init()
    onOpenChanged: init()

    Timer {
        running: win.open && !win.grabReady
        interval: 60
        onTriggered: win.grabReady = true
    }

    function close() {
        ShellState.powerMenuOpen = false;
    }

    function trigger(i) {
        const a = actions[i];
        current = i;
        if (a.confirm && armed !== i) {
            armed = i;
            disarm.restart();
            return;
        }
        close();
        Utils.run(a.cmd);
    }

    Timer {
        id: focusTimer
        interval: 10
        onTriggered: card.forceActiveFocus()
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: win.armed = -1
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open && win.grabReady
        onCleared: win.close()
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: BarLayout.hyprRounding + 14
        color: Theme.alpha(Theme.surface, 0.96)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.8)
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.94
        // Visível logo ao abrir, para a área de cliques não estar vazia quando a focus grab começa.
        visible: win.open || opacity > 0
        focus: win.open

        Behavior on opacity {
            NumberAnim {
                duration: Anim.fast
            }
        }
        Behavior on scale {
            NumberAnim {
                easing.bezierCurve: Anim.emphasized
            }
        }

        Keys.onEscapePressed: win.close()
        Keys.onLeftPressed: {
            win.current = (win.current + win.actions.length - 1) % win.actions.length;
            win.armed = -1;
        }
        Keys.onRightPressed: {
            win.current = (win.current + 1) % win.actions.length;
            win.armed = -1;
        }
        Keys.onReturnPressed: win.trigger(win.current)
        Keys.onEnterPressed: win.trigger(win.current)
        Keys.onPressed: event => {
            const i = win.actions.findIndex(a => a.key === event.key);
            if (i >= 0) {
                win.trigger(i);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            RowLayout {
                id: row
                spacing: 10

                Repeater {
                    model: win.actions

                    ColumnLayout {
                        id: btn

                        required property var modelData
                        required property int index
                        readonly property bool selected: index === win.current
                        readonly property bool isArmed: index === win.armed
                        readonly property bool danger: modelData.confirm

                        spacing: 6

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 72
                            implicitHeight: 72
                            radius: btn.selected ? 24 : 36
                            color: btn.isArmed ? Theme.error : btn.selected ? Theme.primary : Theme.surfaceContainerHigh

                            Behavior on radius {
                                NumberAnim {
                                    easing.bezierCurve: Anim.expressive
                                }
                            }
                            Behavior on color {
                                ColorAnim {}
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                icon: btn.modelData.icon
                                size: 30
                                fill: btn.selected ? 1 : 0
                                color: btn.isArmed ? Theme.readable(Theme.surface, Theme.error, 4.5) : btn.selected ? Theme.onPrimary : btn.danger ? Theme.error : Theme.text
                            }

                            StateLayer {
                                anchors.fill: parent
                                radius: parent.radius
                                onPositionChanged: mouse => {
                                    const g = mapToGlobal(mouse.x, mouse.y);
                                    if (win.lastMouse.x >= 0 && (Math.abs(g.x - win.lastMouse.x) > 1 || Math.abs(g.y - win.lastMouse.y) > 1))
                                        win.current = btn.index;
                                    win.lastMouse = g;
                                }
                                onClicked: win.trigger(btn.index)
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.isArmed ? "Confirmar?" : btn.modelData.label
                            font.pixelSize: 12
                            font.weight: btn.selected ? Font.DemiBold : Font.Normal
                            color: btn.isArmed ? Theme.error : btn.selected ? Theme.text : Theme.textDim
                        }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: win.armed >= 0 ? "Carrega outra vez para confirmar" : "← → escolher · Enter · Esc"
                font.pixelSize: 11
                color: win.armed >= 0 ? Theme.error : Theme.textFaint
            }
        }
    }
}
