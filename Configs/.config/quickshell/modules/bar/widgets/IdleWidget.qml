import qs.components
import qs.services

// Inibidor de inatividade ("cafeína"): impede o ecrã de se apagar e o sistema de suspender.
BarItem {
    icon: "coffee"
    iconFill: ShellState.idleInhibited ? 1 : 0
    iconColor: ShellState.idleInhibited ? Theme.primary : Theme.text
    active: ShellState.idleInhibited
    tooltip: ShellState.idleInhibited ? "Cafeína ligada: o sistema não adormece" : "Cafeína desligada"

    onClicked: ShellState.idleInhibited = !ShellState.idleInhibited
}
