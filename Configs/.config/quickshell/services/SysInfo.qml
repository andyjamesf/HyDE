pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Utilizador, máquina e tempo ligado (para o cabeçalho do centro de controlo).
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    // Fotografia do utilizador (~/.face, a convenção dos gestores de sessão); vazio se não existir.
    property string avatar: ""
    property string host: ""
    property int uptimeSeconds: 0
    readonly property string uptime: {
        const d = Math.floor(uptimeSeconds / 86400);
        const h = Math.floor(uptimeSeconds % 86400 / 3600);
        const m = Math.floor(uptimeSeconds % 3600 / 60);
        return d > 0 ? `${d} d ${h} h` : h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    // Só é lido quando alguém mostra o valor (o centro de controlo chama refresh() ao abrir).
    function refresh() {
        uptimeFile.reload();
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.face`
        printErrors: false
        onLoaded: root.avatar = `file://${path}`
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.host = text().trim()
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = Math.floor(parseFloat(text()))
    }
}
