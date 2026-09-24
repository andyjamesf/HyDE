import qs.components
import qs.services

// Inibidor de inatividade ("cafeína"): impede o ecrã de se apagar e o sistema de suspender.
BarItem {
    icon: "coffee"
    iconFill: ShellState.idleInhibited ? 1 : 0
    iconColor: ShellState.idleInhibited ? Theme.primary : Theme.text
    active: ShellState.idleInhibited
    tooltip: ShellState.idleInhibited ? "Caffeine on: the system stays awake" : "Caffeine off"

    onClicked: ShellState.idleInhibited = !ShellState.idleInhibited
}
