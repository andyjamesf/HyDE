import QtQuick
import Quickshell
import qs.services

// Tooltip ancorada a um item da barra; aceita markup Pango (é o que os scripts do HyDE produzem).
PopupWindow {
    id: tip

    required property Item target
    property string text
    readonly property bool below: BarLayout.atTop

    anchor.item: target
    anchor.rect.y: below ? 0 : -8
    anchor.rect.width: target.width
    anchor.rect.height: target.height + 8
    anchor.edges: below ? Edges.Bottom : Edges.Top
    anchor.gravity: below ? Edges.Bottom : Edges.Top
    visible: true
    color: "transparent"
    implicitWidth: body.implicitWidth + 24
    implicitHeight: body.implicitHeight + 16

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 10
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant
        opacity: 0
        scale: 0.94

        Component.onCompleted: {
            opacity = 1;
            scale = 1;
        }

        Behavior on opacity {
            NumberAnim {
                duration: Anim.fast
            }
        }
        Behavior on scale {
            NumberAnim {
                duration: Anim.fast
            }
        }

        StyledText {
            id: body
            anchors.centerIn: parent
            text: Utils.pango(tip.text)
            textFormat: Text.StyledText
            elide: Text.ElideNone
        }
    }
}
