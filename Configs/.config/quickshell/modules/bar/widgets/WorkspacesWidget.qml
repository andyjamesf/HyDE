import QtQuick
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.services

// Workspaces do Hyprland: sempre pelo menos `shown` visíveis, os ocupados com os ícones das apps,
// e um indicador que desliza até ao workspace ativo deste ecrã. Scroll muda de workspace.
Item {
    id: root

    property var bar
    property bool shown: true

    readonly property var cfg: Config.widgets.workspaces
    readonly property int activeId: bar?.monitor?.activeWorkspace?.id ?? 1
    readonly property int count: Math.max(cfg.shown, activeId, ...Hypr.workspaces.map(w => w.id))

    implicitWidth: row.implicitWidth + 8
    implicitHeight: BarLayout.height

    WheelHandler {
        property real acc: 0
        onWheel: event => {
            acc += event.angleDelta.y;
            if (Math.abs(acc) >= 120) {
                Hypr.dispatchFocusWorkspace(acc > 0 ? "e-1" : "e+1");
                acc = 0;
            }
        }
    }

    Rectangle {
        id: indicator

        readonly property Item target: repeater.count >= root.activeId ? repeater.itemAt(root.activeId - 1) : null

        x: row.x + (target?.x ?? 0)
        width: target?.width ?? 0
        height: Math.round(root.height * 0.64)
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: BarLayout.readable(Theme.primary, 1.8)

        Behavior on x {
            NumberAnim {
                duration: Anim.spatial
                easing.bezierCurve: Anim.expressive
            }
        }
        Behavior on width {
            NumberAnim {
                duration: Anim.spatial
                easing.bezierCurve: Anim.expressive
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: root.height
        spacing: 2

        Repeater {
            id: repeater
            model: root.count

            Item {
                id: ws

                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: wsId === root.activeId
                readonly property var toplevels: Hypr.toplevelsOn(wsId)
                readonly property bool occupied: toplevels.length > 0
                readonly property bool showIcons: root.cfg.appIcons && occupied

                width: Math.max(Math.round(row.height * 0.64), content.implicitWidth + Math.round(row.height * 0.5))
                height: row.height

                StateLayer {
                    anchors.fill: parent
                    anchors.topMargin: Math.round(row.height * 0.18)
                    anchors.bottomMargin: Math.round(row.height * 0.18)
                    highlight: ws.isActive ? "transparent" : Theme.hover
                    onClicked: Hypr.dispatchFocusWorkspace(ws.wsId)
                }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: ws.showIcons ? ws.toplevels.slice(0, root.cfg.maxIcons) : []

                        IconImage {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Math.round(BarLayout.iconSize * 0.9)
                            source: Apps.iconFor(Hypr.appIdOf(modelData))
                        }
                    }

                    StyledText {
                        visible: !ws.showIcons
                        anchors.verticalCenter: parent.verticalCenter
                        text: ws.wsId
                        font.pixelSize: BarLayout.fontSize
                        font.weight: ws.isActive ? Font.Bold : Font.Normal
                        color: ws.isActive ? Theme.onPrimary : ws.occupied ? BarLayout.readable(Theme.text, 4.5) : BarLayout.readable(Theme.textFaint, 2.6)
                    }
                }
            }
        }
    }
}
