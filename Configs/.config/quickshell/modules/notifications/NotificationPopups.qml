import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.services

// Popups das notificações, no canto do ecrã com foco (junto à barra). Cada um entra a deslizar,
// desaparece sozinho ao fim do tempo (que pára enquanto o rato está por cima) e sai a deslizar.
PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property bool active: (Hyprland.focusedMonitor?.name ?? "") === modelData.name

    screen: modelData
    visible: true
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
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    exclusiveZone: 0
    color: "transparent"
    // Só os cartões recebem cliques; o resto da janela deixa-os passar.
    mask: Region {
        item: column
    }

    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: column
        width: parent.width
        spacing: Theme.space2

        Repeater {
            model: win.active ? Notifs.popups : []

            Item {
                id: slot

                required property var modelData
                property bool leaving: false

                width: column.width
                height: card.implicitHeight
                opacity: 0
                x: width

                Component.onCompleted: enter.start()

                function leave() {
                    if (leaving)
                        return;
                    leaving = true;
                    exit.start();
                }

                ParallelAnimation {
                    id: enter
                    NumberAnimation {
                        target: slot
                        property: "x"
                        to: 0
                        duration: Anim.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Anim.emphasized
                    }
                    NumberAnimation {
                        target: slot
                        property: "opacity"
                        to: 1
                        duration: Anim.fast
                    }
                }

                SequentialAnimation {
                    id: exit
                    ParallelAnimation {
                        NumberAnimation {
                            target: slot
                            property: "x"
                            to: slot.width
                            duration: Anim.normal
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.standardAccel
                        }
                        NumberAnimation {
                            target: slot
                            property: "opacity"
                            to: 0
                            duration: Anim.normal
                        }
                    }
                    ScriptAction {
                        script: Notifs.hidePopup(slot.modelData)
                    }
                }

                // Tempo do config.json (5 s); a app só o pode encurtar (expireTimeout vem em ms).
                // As críticas ficam até serem fechadas.
                Timer {
                    readonly property int maxTimeout: Config.widgets.notifications.timeout
                    readonly property real appTimeout: slot.modelData.expireTimeout
                    interval: appTimeout > 0 ? Math.min(appTimeout, maxTimeout) : maxTimeout
                    running: !card.critical && !card.hovered && !slot.leaving
                    onTriggered: slot.leave()
                }

                NotificationCard {
                    id: card
                    width: parent.width
                    notification: slot.modelData
                    popup: true
                    onClosed: slot.leave()
                }
            }
        }
    }
}
