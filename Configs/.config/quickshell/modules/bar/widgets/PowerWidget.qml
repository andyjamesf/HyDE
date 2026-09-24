import qs.components
import qs.services

// Sessão: clique abre o power menu da shell, clique direito o menu rápido.
BarItem {
    icon: "power_settings_new"
    iconColor: Theme.error
    tooltip: "Sessão (clique direito: menu rápido)"
    menu: HydeActions.power

    onClicked: ShellState.togglePowerMenu()
}
