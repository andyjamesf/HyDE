import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.modules.controls

// Histórico de notificações (centro de controlo). Com `limit` mostra só as mais recentes.
ColumnLayout {
    id: root

    property int limit: 0
    property bool showHeader: true
    readonly property var items: limit > 0 ? Notifs.list.slice(0, limit) : Notifs.list

    spacing: 8

    PanelHeader {
        visible: root.showHeader
        icon: Notifs.dnd ? "notifications_off" : "notifications"
        title: "Notificações"
        subtitle: Notifs.count === 0 ? "Nenhuma" : Notifs.count === 1 ? "1 notificação" : `${Notifs.count} notificações`

        IconButton {
            icon: "do_not_disturb_on"
            size: 32
            checked: Notifs.dnd
            onClicked: Notifs.toggleDnd()
        }

        IconButton {
            visible: Notifs.count > 0
            icon: "clear_all"
            size: 32
            onClicked: Notifs.clear()
        }
    }

    StyledText {
        visible: Notifs.count === 0
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        padding: 16
        text: Notifs.dnd ? "Não incomodar está ligado" : "Tudo em dia"
        color: Theme.textFaint
    }

    Repeater {
        model: root.items

        NotificationCard {
            required property var modelData
            Layout.fillWidth: true
            notification: modelData
        }
    }
}
