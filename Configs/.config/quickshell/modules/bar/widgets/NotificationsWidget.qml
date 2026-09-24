import qs.components
import qs.services

// Notificações. Nesta fase ainda são do swaync (fase 3: servidor próprio).
// Clique abre o painel, clique direito liga/desliga o "Não incomodar".
BarItem {
    shown: Notifs.available
    icon: Notifs.dnd ? "notifications_off" : Notifs.count > 0 ? "notifications_unread" : "notifications"
    iconFill: Notifs.count > 0 ? 1 : 0
    iconColor: Notifs.dnd ? Theme.textFaint : Notifs.count > 0 ? Theme.primary : Theme.text
    text: Notifs.count > 0 ? String(Notifs.count) : ""
    tooltip: (Notifs.dnd ? "Do not disturb on\n" : "") + (Notifs.count > 0 ? `${Notifs.count} notifications` : "No notifications")

    onClicked: Notifs.togglePanel()
    onRightClicked: Notifs.toggleDnd()
}
