import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

// A barra de um ecrã. As secções (esquerda, centro, direita) e as ilhas vêm do config.json.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool atTop: BarLayout.atTop
    readonly property bool islands: BarLayout.islands
    readonly property int gap: BarLayout.margin

    screen: modelData
    anchors {
        top: bar.atTop
        bottom: !bar.atTop
        left: true
        right: true
    }
    implicitHeight: BarLayout.height + gap
    color: "transparent"
    visible: !ShellState.barHidden

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    IdleInhibitor {
        window: bar
        enabled: ShellState.idleInhibited
    }

    // Fundo do estilo "continuous".
    Rectangle {
        anchors.fill: parent
        visible: !bar.islands
        color: BarLayout.pillColor
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: bar.atTop ? bar.gap : 0
        anchors.bottomMargin: bar.atTop ? 0 : bar.gap
        anchors.leftMargin: bar.islands ? bar.gap : 4
        anchors.rightMargin: bar.islands ? bar.gap : 4

        Section {
            id: leftSection
            anchors.left: parent.left
            barRef: bar
            islandList: BarLayout.left
        }

        // Centrado, mas desviado quando os lados precisam do espaço (como o CenterBox do GTK).
        // Se não couber de todo entre os lados, esconde-se em vez de ficar por cima deles.
        Section {
            visible: parent.width - leftSection.width - rightSection.width - 2 * BarLayout.spacing >= implicitWidth
            x: Math.max(leftSection.width + BarLayout.spacing, Math.min((parent.width - width) / 2, rightSection.x - width - BarLayout.spacing))
            barRef: bar
            islandList: BarLayout.center
        }

        Section {
            id: rightSection
            anchors.right: parent.right
            barRef: bar
            islandList: BarLayout.right
        }
    }

    component Section: Row {
        id: section

        property var islandList: []
        property var barRef

        height: parent.height
        spacing: BarLayout.spacing

        Repeater {
            model: section.islandList

            Island {
                required property var modelData
                widgets: modelData
                bar: section.barRef
            }
        }
    }
}
