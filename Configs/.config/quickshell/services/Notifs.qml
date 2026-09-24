pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Servidor de notificações da shell (substitui o swaync/dunst do HyDE).
//
// - Todas as notificações ficam no histórico (até `historySize`), exceto as marcadas como
//   "transient" pela app, que só aparecem como popup.
// - Os popups respeitam o "Não incomodar" (só as críticas passam) e desaparecem sozinhos.
// - As notificações de volume e brilho dos scripts do HyDE (volumecontrol.sh e
//   brightnesscontrol.sh) são ignoradas quando o OSD da shell está ligado: fariam o mesmo
//   que o OSD, em duplicado.
Singleton {
    id: root

    readonly property bool available: true
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length
    property var popups: []
    // Hora de chegada de cada notificação (o protocolo não a indica).
    property var times: ({})

    readonly property bool dnd: Prefs.dnd

    function toggleDnd() {
        Prefs.dnd = !Prefs.dnd;
        Prefs.save();
    }

    // Compatibilidade com o widget da barra: abre o histórico no centro de controlo.
    function togglePanel() {
        ShellState.toggleControlCenter("notifications");
    }

    function clear() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function dismiss(n) {
        n.dismiss();
    }

    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
        // As transitórias não ficam no histórico.
        if (n.transient && n.tracked)
            n.expire();
    }

    function timeOf(n) {
        return times[n.id] ?? new Date();
    }

    function isHydeOsd(n) {
        return Config.widgets.osd.enabled && n.appName === "HyDE Notify" && String(n.appIcon).includes("/Wallbash-Icon/media/");
    }

    // Ícone/imagem a mostrar: imagem da notificação, ícone da app (caminho ou nome do tema).
    function imageOf(n) {
        if (n.image)
            return n.image;
        const icon = n.appIcon || n.desktopEntry || "";
        if (icon.startsWith("/"))
            return `file://${icon}`;
        if (icon.startsWith("file://") || icon.startsWith("image://"))
            return icon;
        return icon ? Quickshell.iconPath(icon, true) : "";
    }

    function onArrived(n) {
        if (isHydeOsd(n))
            return;
        n.tracked = true;
        const t = Object.assign({}, times);
        t[n.id] = new Date();
        times = t;

        // Histórico limitado: as mais antigas saem.
        const tracked = server.trackedNotifications.values;
        for (let i = 0; i < tracked.length - Config.widgets.notifications.historySize; i++)
            tracked[i].expire();

        if (!dnd || n.urgency === NotificationUrgency.Critical)
            popups = [n].concat(popups.filter(p => p !== n)).slice(0, Config.widgets.notifications.maxPopups);
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true

        onNotification: n => root.onArrived(n)
    }

    // Com o centro de controlo aberto os popups saem: as notificações já estão lá, no histórico.
    Connections {
        target: ShellState
        function onControlCenterOpenChanged() {
            if (ShellState.controlCenterOpen)
                for (const n of root.popups.slice())
                    root.hidePopup(n);
        }
    }

    // Uma notificação fechada (pela app ou por nós) sai dos popups.
    Instantiator {
        model: root.popups
        delegate: Connections {
            required property var modelData
            target: modelData
            function onClosed() {
                root.popups = root.popups.filter(p => p !== modelData);
            }
        }
    }
}
