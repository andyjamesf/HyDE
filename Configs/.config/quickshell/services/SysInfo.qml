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
        id: face
        path: `${Quickshell.env("HOME")}/.face`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        // O número no fim obriga a Image a ler a foto nova (senão mostrava a que tinha em cache).
        onLoaded: root.avatar = `file://${path}?v=${Date.now()}`
        onLoadFailed: root.avatar = ""
    }

    // Mudar a foto: o seletor de ficheiros do sistema (portal) e a imagem escolhida fica copiada para
    // ~/.face (onde os gestores de sessão e o lockscreen também a procuram).
    function chooseAvatar() {
        if (!picker.running)
            picker.running = true;
    }

    Process {
        id: picker
        command: ["python3", Quickshell.shellPath("scripts/pick_file.py"), "Choose your photo", "Images:*.png;*.jpg;*.jpeg;*.webp;*.bmp", `${Quickshell.env("HOME")}/Pictures`]
        stdout: StdioCollector {
            onStreamFinished: {
                const src = text.trim();
                if (src !== "")
                    Quickshell.execDetached(["cp", "-f", "--", src, face.path]);
            }
        }
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
