pragma Singleton
import QtQuick
import Quickshell

// AI usage icon ("ai" in StatusPillConfig.icons): how much of each AI tool's limit is used, from
// the same scripts as the HyDE shell's bar widget (~/.local/bin/ai-usage-watch). The icon is only
// the symbol, coloured by the tool closest to its limit; a click fetches fresh numbers and shows
// them under the icon. It hides itself when none of the commands gives an answer (e.g. a PC
// without them). (Named AiUsageConfig because services/AiUsage.qml is the service.)
Singleton {
    // The tools, in the order shown: label, how often to fetch (seconds) and the command, which
    // prints Waybar-style JSON ({ text, class }). Delete an entry to leave a tool out.
    readonly property var agents: [
        {
            name: "claude",
            label: "Claude",
            period: 120,
            cmd: "/usr/bin/claude-usage --waybar --show-5h"
        },
        {
            name: "codex",
            label: "Codex",
            period: 120,
            cmd: "codex-credits"
        },
        {
            name: "copilot",
            label: "Copilot",
            period: 300,
            cmd: "copilot-credits"
        }
    ]
    // How long the usage stays on screen after a click, in milliseconds. Default 8000.
    readonly property int showMs: 8000
}
