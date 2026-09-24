import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Painel que abre por baixo (ou por cima) de um widget da barra, com o conteúdo em `content`.
// Entra com um deslize curto e um fade. Fecha ao clicar fora ou com Esc: usa a focus grab do
// Hyprland (e não a do xdg_popup, que só funciona se a abertura vier de um clique — falha quando
// a popout é aberta por IPC). A barra faz parte da grab, para os cliques nela continuarem a
// funcionar (trocar de popout, fechar no mesmo widget).
PopupWindow {
    id: popout

    required property Item target
    property Component content
    property var barWindow: null
    readonly property bool below: BarLayout.atTop

    signal dismissed

    anchor.item: target
    anchor.rect.y: below ? 0 : -10
    anchor.rect.width: target.width
    anchor.rect.height: target.height + 10
    anchor.edges: below ? Edges.Bottom : Edges.Top
    anchor.gravity: below ? Edges.Bottom : Edges.Top
    anchor.adjustment: PopupAdjustment.Slide
    visible: true
    color: "transparent"
    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight + 10

    onVisibleChanged: if (!visible)
        dismissed()

    function close() {
        visible = false;
    }

    HyprlandFocusGrab {
        windows: popout.barWindow ? [popout, popout.barWindow] : [popout]
        active: popout.visible
        onCleared: popout.close()
    }

    Rectangle {
        id: bg

        implicitWidth: loader.implicitWidth + 32
        implicitHeight: loader.implicitHeight + 32
        width: parent.width
        height: implicitHeight
        y: popout.below ? 0 : 10
        radius: BarLayout.hyprRounding + 10
        color: Theme.alpha(Theme.surfaceContainer, 0.97)
        border.width: 1
        border.color: Theme.alpha(Theme.outlineVariant, 0.8)
        focus: true
        Keys.onEscapePressed: popout.close()

        opacity: 0
        transform: Translate {
            id: slide
            y: popout.below ? -8 : 8
        }

        Component.onCompleted: opacity = 1

        Behavior on opacity {
            NumberAnim {
                duration: Anim.normal
            }
        }

        Loader {
            id: loader
            anchors.centerIn: parent
            sourceComponent: popout.content
        }
    }

    // O Translate não é um Item (não aceita Behavior), por isso o deslize é uma animação à parte.
    NumberAnimation {
        running: true
        target: slide
        property: "y"
        to: 0
        duration: Anim.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.emphasized
    }
}
