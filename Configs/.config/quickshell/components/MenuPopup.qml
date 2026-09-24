import QtQuick
import Quickshell
import qs.services

// Menu em popup ancorado a um item da barra.
// Entradas: { label, cmd } | { label, action: função } | { label, items } | { sep: true };
// `checked: true` mostra um visto à direita (para opções exclusivas, como o layout atual).
// Um submenu substitui a lista no mesmo sítio, com uma linha "Back" no topo.
PopupWindow {
    id: menu

    required property Item target
    required property var items
    property var stack: [items]
    // Submenus a abrir logo ao criar (índices em cada nível); usado pelos testes por IPC.
    property var path: []
    readonly property var current: stack[stack.length - 1]
    readonly property bool below: BarLayout.atTop

    signal dismissed

    anchor.item: target
    anchor.rect.y: below ? 0 : -8
    anchor.rect.width: target.width
    anchor.rect.height: target.height + 8
    anchor.edges: below ? Edges.Bottom : Edges.Top
    anchor.gravity: below ? Edges.Bottom : Edges.Top
    grabFocus: true
    visible: true
    color: "transparent"
    // Largura à medida do texto mais comprido do nível atual (entre 200 e 360 px).
    implicitWidth: {
        let widest = 0;
        for (const item of current)
            if (!item.sep)
                widest = Math.max(widest, measure(item.label ?? ""));
        return Math.round(Math.min(360, Math.max(200, widest + 2 * Theme.space3 + 18 + Theme.space2 + 2 * (Theme.space1 + 1))));
    }

    function measure(text) {
        return metrics.advanceWidth(text);
    }

    FontMetrics {
        id: metrics
        font.family: Config.appearance.font
        font.pixelSize: Theme.bodyMedium
    }
    implicitHeight: list.implicitHeight + 2 * Theme.space1 + 2

    onVisibleChanged: if (!visible)
        dismissed()

    Component.onCompleted: {
        let s = [items];
        for (const i of path) {
            const entry = s[s.length - 1][i];
            if (!entry?.items)
                break;
            s.push(entry.items);
        }
        stack = s;
    }

    function activate(item) {
        if (item.back) {
            stack = stack.slice(0, -1);
        } else if (item.items) {
            stack = stack.concat([item.items]);
        } else if (item.action) {
            item.action();
            menu.visible = false;
        } else if (item.cmd) {
            Utils.run(item.cmd);
            menu.visible = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.border
        focus: true
        Keys.onEscapePressed: menu.visible = false

        Column {
            id: list
            anchors.fill: parent
            anchors.margins: Theme.space1 + 1

            Repeater {
                model: (menu.stack.length > 1 ? [
                        {
                            back: true
                        }
                    ] : []).concat(menu.current)

                delegate: Item {
                    id: row

                    required property var modelData

                    width: list.width
                    height: modelData.sep ? 9 : 34

                    Rectangle {
                        visible: row.modelData.sep === true
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Theme.outlineVariant
                    }

                    StateLayer {
                        visible: !row.modelData.sep
                        anchors.fill: parent
                        radius: Theme.shapeSmall
                        onClicked: menu.activate(row.modelData)

                        MaterialIcon {
                            id: backIcon
                            visible: row.modelData.back === true
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.space3
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "arrow_back"
                            size: 18
                        }

                        StyledText {
                            anchors.left: row.modelData.back ? backIcon.right : parent.left
                            anchors.right: arrow.left
                            anchors.leftMargin: row.modelData.back ? Theme.space2 : Theme.space3
                            font.pixelSize: Theme.bodyMedium
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.back ? "Back" : (row.modelData.label ?? "")
                        }

                        MaterialIcon {
                            id: arrow
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.space3
                            anchors.verticalCenter: parent.verticalCenter
                            icon: row.modelData.items ? "chevron_right" : row.modelData.checked ? "check" : ""
                            size: 18
                            color: row.modelData.checked ? Theme.primary : Theme.textDim
                        }
                    }
                }
            }
        }
    }
}
