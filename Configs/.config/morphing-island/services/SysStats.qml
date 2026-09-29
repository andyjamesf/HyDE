pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PC statistics for the System page (components/CcSystemPage.qml), from scripts/sysstats.py. The
// script only runs while something shows them (users > 0), every 2 seconds.
Singleton {
    id: root

    // How many views show the stats; the script runs while > 0.
    property int users: 0
    // The last reading (see scripts/sysstats.py), null until the first arrives.
    property var data: null

    // 1.2 GB, 850 MB…
    function bytes(n) {
        if (!(n > 0))
            return "0 B";
        const u = ["B", "KB", "MB", "GB", "TB"];
        const i = Math.min(u.length - 1, Math.floor(Math.log(n) / Math.log(1024)));
        const v = n / Math.pow(1024, i);
        return `${v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)} ${u[i]}`;
    }

    Process {
        command: ["python3", Quickshell.shellPath("scripts/sysstats.py"), "2"]
        running: root.users > 0
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.data = JSON.parse(line);
                } catch (e) {}
            }
        }
    }
}
