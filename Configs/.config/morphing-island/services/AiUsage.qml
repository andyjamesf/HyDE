pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// AI usage (config/AiUsageConfig.qml): one ai-usage-watch stream per tool, always running so the
// icon's colour stays current. refresh() asks every stream for fresh numbers at once (SIGUSR1).
Singleton {
    id: root

    // name → { text, cls }: the value as plain text ("61% 3h06m") and the script's class.
    property var states: ({})
    // At least one tool answered: the icon shows only then.
    readonly property bool available: Object.values(states).some(s => s.text !== "")
    // "high" | "mid" | "low": the tool closest to its limit.
    readonly property string worst: {
        const classes = Object.values(states).map(s => s.cls);
        if (classes.some(c => c.includes("critical") || c.endsWith("-high")))
            return "high";
        if (classes.some(c => c.endsWith("-mid")))
            return "mid";
        return "low";
    }
    // One line per tool, e.g. "Claude   61% · 3h06m".
    readonly property string summary: AiUsageConfig.agents.map(a => {
        const s = states[a.name];
        return `${a.label}   ${s && s.text !== "" ? s.text : "…"}`;
    }).join("\n")

    function refresh() {
        Quickshell.execDetached(["pkill", "-USR1", "-f", "[a]i-usage-watch "]);
    }

    // The scripts write "<span …>icon</span> value <span …>icon</span> value": keep the values.
    // Markup and icons (Nerd Font glyphs, symbols with no letter or digit) are dropped.
    function plain(markup) {
        return Array.from(String(markup).replace(/<[^>]*>/g, " ")).filter(ch => {
            const c = ch.codePointAt(0);
            return !((c >= 0xE000 && c <= 0xF8FF) || c >= 0xF0000);
        }).join("").trim().split(/\s+/).filter(x => /[A-Za-z0-9]/.test(x)).join(" · ");
    }

    function _set(name, line) {
        let d;
        try {
            d = JSON.parse(line);
        } catch (e) {
            return;
        }
        const s = Object.assign({}, states);
        s[name] = {
            text: plain(d.text ?? ""),
            cls: Array.isArray(d.class) ? d.class.join(" ") : (d.class ?? "")
        };
        states = s;
    }

    Instantiator {
        model: AiUsageConfig.agents

        Process {
            required property var modelData
            command: ["sh", "-c", `exec ai-usage-watch ${modelData.name} ${modelData.period} -- ${modelData.cmd}`]
            running: true
            stdout: SplitParser {
                onRead: line => root._set(modelData.name, line)
            }
        }
    }
}
