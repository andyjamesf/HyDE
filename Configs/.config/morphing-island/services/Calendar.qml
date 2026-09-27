pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Calendars and their events, for the calendar view (components/CalendarView.qml).
//
// The work is done by scripts/ical_events.py: it reads the calendars listed in
// ~/.local/share/quickshell/calendars.json (links or local .ics files), expands recurring events and
// writes ~/.cache/quickshell/calendar.json, which this service watches. The HyDE Quickshell shell
// uses the same two files, so both shells show the same calendars.
//
// Adding a calendar: addLink(url) for iCal/webcal links, addFromClipboard() for the link in the
// clipboard, addFile() opens the system file chooser and copies the chosen .ics to
// ~/.local/share/quickshell/calendars/. setColor(index, "#rrggbb") and remove(index) edit the list.
Singleton {
    id: root

    readonly property string dataDir: `${Paths.dataHome}/quickshell`
    readonly property string configPath: `${dataDir}/calendars.json`
    readonly property string filesDir: `${dataDir}/calendars`

    // [{ name, url | path, color }]
    property var calendars: []
    // [{ title, location, allDay, start: Date, end: Date, calendar, color }], by start. The colour
    // comes from the calendar's entry, so changing it applies at once.
    readonly property var events: {
        const colors = {};
        for (const c of calendars)
            colors[c.name] = c.color;
        return calendars.length === 0 ? [] : _events.map(e => Object.assign({}, e, {
                    color: colors[e.calendar] || e.color
                }));
    }
    property var _events: []
    // Result of an add that finishes later (the clipboard, the file chooser): what to tell the user.
    signal notice(string text, bool error)
    // "Name: reason" for calendars that could not be read last time.
    property var errors: []
    readonly property bool loading: fetcher.running
    property real lastRun: 0

    // Downloads the calendars again (at most every 2 minutes unless `force`).
    function refresh(force) {
        if (calendars.length === 0 || fetcher.running)
            return;
        if (!force && Date.now() - lastRun < 120000)
            return;
        lastRun = Date.now();
        fetcher.running = true;
    }

    // "2026-09-25" (all day) is a local date, not UTC midnight.
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

    // Events touching a day (multi-day ones show on every day they cover).
    function eventsOn(day) {
        const start = new Date(day.getFullYear(), day.getMonth(), day.getDate());
        const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 1);
        return events.filter(e => e.start < end && (e.end > start || (e.end.getTime() === e.start.getTime() && e.start >= start)));
    }

    // Adds an iCal link (https://, http:// or webcal://). Returns "" or why it was refused.
    function addLink(link) {
        const url = String(link ?? "").trim();
        if (!/^(https?|webcal):\/\/\S+$/i.test(url))
            return "Paste an https:// or webcal:// link to an iCal calendar";
        if (calendars.some(c => c.url === url))
            return "That calendar is already added";
        _add({
            name: _nameForLink(url),
            url: url
        });
        return "";
    }

    // Adds the iCal link currently in the clipboard (answers through `notice`).
    function addFromClipboard() {
        if (!clipboard.running)
            clipboard.running = true;
    }

    // Colour of calendar `index` ("#rrggbb").
    function setColor(index, color) {
        if (!calendars[index])
            return;
        const list = calendars.slice();
        list[index] = Object.assign({}, list[index], {
            color: color
        });
        _write(list, false);
    }

    // Opens the system file chooser; the chosen .ics is copied next to the list and added.
    function addFile() {
        if (!picker.running)
            picker.running = true;
    }

    function remove(index) {
        const c = calendars[index];
        if (!c)
            return;
        // A copied .ics goes too (only files inside our own folder).
        if (c.path && c.path.startsWith(filesDir + "/"))
            Quickshell.execDetached(["rm", "-f", "--", c.path]);
        _write(calendars.filter((_, i) => i !== index));
    }

    function _add(entry) {
        entry.color = CalendarConfig.colors[calendars.length % CalendarConfig.colors.length];
        _write(calendars.concat([entry]));
        notice(`Added "${entry.name}"`, false);
    }

    // Saves the list; `refetch` (default true) reads the calendars again (not needed for a colour).
    function _write(list, refetch) {
        calendars = list;
        configFile.setText(JSON.stringify({
            calendars: list
        }, null, 2) + "\n");
        if (refetch !== false) {
            lastRun = 0;
            refreshSoon.restart();
        }
    }

    // A readable name for a link: Google/Outlook/iCloud by host, else the host itself.
    function _nameForLink(url) {
        const host = (url.match(/^[a-z]+:\/\/([^\/?#]+)/i)?.[1] ?? "").toLowerCase();
        const base = host.includes("google.") ? "Google Calendar" : host.includes("outlook.") || host.includes("office365.") ? "Outlook" : host.includes("icloud.") ? "iCloud" : host.replace(/^www\./, "");
        const taken = calendars.filter(c => c.name === base || c.name.startsWith(base + " ")).length;
        return taken > 0 ? `${base} ${taken + 1}` : base;
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", "--", filesDir])

    // The list of calendars (the HyDE shell may change it too: watched).
    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.calendars = JSON.parse(text()).calendars ?? [];
            } catch (e) {
                root.calendars = [];
            }
            root.refresh(false);
        }
        // No list (never set up, or deleted): no calendars (and so no events).
        onLoadFailed: root.calendars = []
    }

    // The events the script wrote.
    FileView {
        path: `${Paths.cacheHome}/quickshell/calendar.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.errors = d.errors ?? [];
                root._events = (d.events ?? []).map(e => Object.assign({}, e, {
                            start: root.parseDate(e.start, e.allDay),
                            end: root.parseDate(e.end, e.allDay)
                        }));
            } catch (e) {}
        }
    }

    Timer {
        id: refreshSoon
        interval: 300
        onTriggered: root.refresh(true)
    }

    Timer {
        interval: Math.max(1, CalendarConfig.refreshMinutes) * 60000
        running: root.calendars.length > 0
        repeat: true
        onTriggered: root.refresh(true)
    }

    Process {
        id: fetcher
        command: ["python3", Quickshell.shellPath("scripts/ical_events.py")]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "")
                console.info("calendar:", text.trim())
        }
    }

    Process {
        id: clipboard
        command: ["wl-paste", "--no-newline", "--type", "text"]
        stdout: StdioCollector {
            onStreamFinished: {
                const why = root.addLink(text);
                if (why !== "")
                    root.notice(text.trim() === "" ? "The clipboard is empty: copy an iCal link first" : why, true);
            }
        }
    }

    // The chosen .ics is copied (the original may be moved or deleted later), then added.
    Process {
        id: picker
        command: ["python3", Quickshell.shellPath("scripts/pick_file.py"), "Add a calendar (.ics)", "iCalendar:*.ics;*.ICS"]
        stdout: StdioCollector {
            onStreamFinished: {
                const src = text.trim();
                if (src === "")
                    return;
                const base = src.slice(src.lastIndexOf("/") + 1);
                const dst = `${root.filesDir}/${Date.now()}-${base}`;
                copier.dst = dst;
                copier.name = base.replace(/\.ics$/i, "");
                copier.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && cp -- "$1" "$2"', "sh", src, dst];
                copier.running = true;
            }
        }
    }

    Process {
        id: copier
        property string dst: ""
        property string name: ""
        onExited: code => {
            if (code === 0)
                root._add({
                    name: copier.name,
                    path: copier.dst
                });
        }
    }
}
