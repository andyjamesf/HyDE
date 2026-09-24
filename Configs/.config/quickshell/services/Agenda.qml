pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Eventos dos calendários (Google Calendar ou outro com endereço iCal), para o calendário da barra.
// O trabalho é feito por scripts/ical_events.py, que descarrega os calendários listados em
// ~/.local/share/quickshell/calendars.json e escreve ~/.cache/quickshell/calendar.json; este
// serviço vigia esse ficheiro. Atualiza a cada 15 minutos e quando se abre o calendário.
Singleton {
    id: root

    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"
    readonly property string configPath: `${dataHome}/quickshell/calendars.json`

    property bool configured: false
    property var events: []
    property var errors: []
    property real lastRun: 0

    // Atualiza, mas não mais do que uma vez a cada 2 minutos (abrir e fechar a popout seguido).
    function refresh() {
        if (configured && Date.now() - lastRun > 120000) {
            lastRun = Date.now();
            fetcher.running = true;
        }
    }

    // "2026-09-25" (dia inteiro) tem de ser uma data local, não meia-noite UTC.
    function parseDate(s, allDay) {
        if (allDay) {
            const [y, m, d] = s.slice(0, 10).split("-").map(Number);
            return new Date(y, m - 1, d);
        }
        return new Date(s);
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // Eventos que tocam um dia (os de vários dias aparecem em todos).
    function eventsOn(day) {
        const start = new Date(day.getFullYear(), day.getMonth(), day.getDate());
        const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 1);
        return events.filter(e => e.start < end && (e.end > start || (e.end.getTime() === e.start.getTime() && e.start >= start)));
    }

    function upcoming(count) {
        const now = new Date();
        return events.filter(e => e.end > now).slice(0, count);
    }

    function openInBrowser(day) {
        Utils.run(`xdg-open https://calendar.google.com/calendar/r/day/${day.getFullYear()}/${day.getMonth() + 1}/${day.getDate()}`);
    }

    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.configured = true;
            root.lastRun = 0;
            root.refresh();
        }
        onLoadFailed: root.configured = false
    }

    FileView {
        path: `${root.cacheHome}/quickshell/calendar.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.errors = d.errors ?? [];
                root.events = (d.events ?? []).map(e => Object.assign({}, e, {
                            start: root.parseDate(e.start, e.allDay),
                            end: root.parseDate(e.end, e.allDay)
                        }));
            } catch (e) {}
        }
    }

    Process {
        id: fetcher
        command: ["python3", Quickshell.shellPath("scripts/ical_events.py")]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.warn("calendar:", text.trim())
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.configured
        onTriggered: {
            root.lastRun = 0;
            root.refresh();
        }
    }
}
