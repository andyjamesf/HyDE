import QtQuick
import qs.components
import qs.services

// Um grupo de widgets. No estilo "islands" tem fundo próprio arredondado; no "continuous" é só
// um contentor sobre o fundo da barra. Esconde-se quando nenhum dos widgets tem nada a mostrar.
Item {
    id: root

    required property var widgets
    required property var bar
    readonly property bool islands: BarLayout.islands

    // Visível se algum widget quiser aparecer (ver WidgetLoader.wanted).
    visible: {
        for (let i = 0; i < repeater.count; i++)
            if (repeater.itemAt(i)?.wanted)
                return true;
        return false;
    }
    implicitWidth: row.implicitWidth + (islands ? Math.round(BarLayout.height * 0.25) : 0)
    implicitHeight: BarLayout.height
    // Só corta o conteúdo enquanto a largura anima (senão letras e símbolos à beira ficavam cortados).
    clip: widthAnim.running

    Behavior on implicitWidth {
        NumberAnim {
            id: widthAnim
            duration: Anim.normal
            easing.bezierCurve: Anim.emphasized
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.islands
        radius: BarLayout.radius
        color: BarLayout.pillColor
        border.width: 1
        border.color: BarLayout.pillBorder

        Behavior on color {
            ColorAnim {}
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height

        Repeater {
            id: repeater
            model: root.widgets

            WidgetLoader {
                required property string modelData
                name: modelData
                bar: root.bar
                height: row.height
            }
        }
    }
}
