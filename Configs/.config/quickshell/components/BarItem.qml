import QtQuick
import Quickshell.Widgets
import qs.services

// Elemento base dos widgets da barra: ícone (Material ou imagem), texto, tooltip, os três botões
// do rato, scroll, um menu opcional e uma popout (painel) que abre com o clique esquerdo.
// Conteúdo extra pode ser acrescentado como filhos.
Item {
    id: root

    property string icon
    property real iconFill: 0
    property color iconColor: Theme.text
    property string image
    property string text
    property color textColor: Theme.text
    property bool rich: false
    property string fontFamily: Config.appearance.font
    property int maxTextWidth: 10000
    property string tooltip
    property var menu: null
    property bool menuOnLeftClick: false
    property bool active: false
    property int padding: Math.round(BarLayout.height * 0.2)

    // Os widgets dizem se têm alguma coisa para mostrar através de `shown` (e não de `visible`,
    // que depende também dos pais). O WidgetLoader e a Island usam-no para se esconderem.
    property bool shown: true

    property bool menuOpen: false
    property Component popout: null
    // Nome para abrir esta popout por IPC (`qs ipc call bar popout <nome>`).
    property string popoutName
    property var bar

    // Só uma popout aberta de cada vez: abrir esta fecha a anterior.
    onPopoutOpenChanged: if (popoutOpen)
        ShellState.popoutOwner = root
    Connections {
        target: ShellState
        function onPopoutOwnerChanged() {
            if (ShellState.popoutOwner !== root)
                root.popoutOpen = false;
        }
    }
    property bool popoutOpen: false
    // O clique fora que fecha a popout pode ser neste mesmo widget; sem isto reabria logo.
    property real popoutClosedAt: 0
    readonly property bool hovered: layer.containsMouse
    default property alias content: row.data

    signal clicked
    signal rightClicked
    signal middleClicked
    signal scrolled(int direction)

    visible: shown
    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: BarLayout.height

    StateLayer {
        id: layer
        anchors.fill: parent
        anchors.topMargin: Math.round(BarLayout.height * 0.14)
        anchors.bottomMargin: Math.round(BarLayout.height * 0.14)
        active: root.active || root.menuOpen || root.popoutOpen

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.menu && !root.menuOnLeftClick)
                    root.menuOpen = true;
                root.rightClicked();
            } else if (mouse.button === Qt.MiddleButton) {
                root.middleClicked();
            } else {
                if (root.popout && Date.now() - root.popoutClosedAt > 300)
                    root.popoutOpen = !root.popoutOpen;
                if (root.menu && root.menuOnLeftClick)
                    root.menuOpen = true;
                root.clicked();
            }
        }
        onScrolled: direction => root.scrolled(direction)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(BarLayout.height * 0.15)

        IconImage {
            visible: root.image !== ""
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: BarLayout.iconSize
            source: root.image
        }

        MaterialIcon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            fill: root.iconFill
            size: BarLayout.iconSize
            color: BarLayout.readable(root.iconColor, 3)
        }

        StyledText {
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTextWidth)
            text: root.rich ? Utils.pango(root.text, c => BarLayout.readable(c, 3)) : root.text
            textFormat: root.rich ? Text.StyledText : Text.PlainText
            color: BarLayout.readable(root.textColor, 4.5)
            font.family: root.fontFamily
            font.pixelSize: BarLayout.fontSize
        }
    }

    Timer {
        id: tipDelay
        interval: 500
        running: root.hovered && root.tooltip !== "" && !root.menuOpen && !root.popoutOpen
    }

    Loader {
        active: root.hovered && !tipDelay.running && root.tooltip !== "" && !root.menuOpen && !root.popoutOpen
        sourceComponent: Tooltip {
            target: root
            text: root.tooltip
        }
    }

    Loader {
        active: root.menuOpen
        sourceComponent: MenuPopup {
            target: root
            items: root.menu
            onDismissed: root.menuOpen = false
        }
    }

    Loader {
        active: root.popoutOpen
        sourceComponent: Popout {
            target: root
            content: root.popout
            barWindow: root.bar ?? null
            onDismissed: {
                root.popoutOpen = false;
                root.popoutClosedAt = Date.now();
            }
        }
    }

    Connections {
        target: ShellState
        enabled: root.popoutName !== ""
        function onRequestedPopoutChanged() {
            const screenOk = !root.bar?.screen || ShellState.requestedPopoutScreen === "" || ShellState.requestedPopoutScreen === root.bar.screen.name;
            if (ShellState.requestedPopout === root.popoutName && screenOk && root.visible)
                root.popoutOpen = true;
        }
    }
}
