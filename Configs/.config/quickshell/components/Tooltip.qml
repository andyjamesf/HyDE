import QtQuick
import Quickshell
import qs.services

// Tooltip ancorada a um item (da barra ou de um painel); aceita markup Pango (é o que os scripts
// do HyDE produzem). Textos longos quebram a linha em vez de sair do ecrã.
PopupWindow {
    id: tip

    required property Item target
    property string text
    // Na barra, abre para dentro do ecrã; nos painéis, quem a usa escolhe o lado.
    property bool below: BarLayout.atTop

    anchor.item: target
    anchor.rect.y: below ? 0 : -Theme.space2
    anchor.rect.width: target.width
    anchor.rect.height: target.height + Theme.space2
    anchor.edges: below ? Edges.Bottom : Edges.Top
    anchor.gravity: below ? Edges.Bottom : Edges.Top
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    visible: true
    color: "transparent"
    implicitWidth: body.width + 2 * Theme.space3
    implicitHeight: body.implicitHeight + 2 * Theme.space2

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shapeSmall
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.border
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

        // Largura natural até 360 px; a partir daí, quebra a linha.
        StyledText {
            id: body
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 360)
            text: Utils.pango(tip.text)
            textFormat: Text.StyledText
            font.pixelSize: Theme.bodySmall
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
    }
}
