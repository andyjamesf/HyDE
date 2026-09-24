import qs.components
import qs.services

// Abre o centro de controlo.
BarItem {
    icon: "tune"
    iconFill: ShellState.controlCenterOpen ? 1 : 0
    iconColor: Theme.primary
    active: ShellState.controlCenterOpen
    tooltip: "Centro de controlo"

    onClicked: ShellState.toggleControlCenter("")
}
