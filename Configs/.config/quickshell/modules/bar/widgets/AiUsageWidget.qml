import QtQuick
import qs.components
import qs.services

// Uso das ferramentas de IA (Claude Code, Codex, Copilot), com os scripts do utilizador
// (~/.local/bin/ai-usage-watch). Fica recolhido atrás de um botão: o ícone fica vermelho se algum
// estiver perto do limite, a tooltip resume os três e o clique mostra/esconde os detalhes
// (a escolha fica guardada). Clique num dos detalhes força uma atualização desse.
Row {
    id: root

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
    readonly property bool expanded: Prefs.aiExpanded
    // Estado de cada agente (texto sem markup e classe), preenchido pelos streams abaixo.
    property var states: ({})
    readonly property bool anyData: Object.values(states).some(s => s.text !== "")
    readonly property string worst: {
        const classes = Object.values(states).map(s => s.cls);
        if (classes.some(c => c.includes("critical") || c.endsWith("-high")))
            return "high";
        if (classes.some(c => c.endsWith("-mid")))
            return "mid";
        return "low";
    }
    property bool shown: anyData

    function setState(name, text, cls) {
        const s = Object.assign({}, states);
        s[name] = {
            text: text.replace(/<[^>]*>/g, "").trim(),
            cls: cls
        };
        states = s;
    }

    BarItem {
        id: toggle
        height: root.height
        icon: "smart_toy"
        iconFill: root.expanded ? 1 : 0
        iconColor: root.worst === "high" ? Theme.error : root.worst === "mid" ? Theme.warning : Theme.primary
        active: root.expanded
        tooltip: root.agents.map(a => `<b>${a.label}</b>  ${root.states[a.name]?.text || "…"}`).join("\n") + `\n\n${root.expanded ? "Clique para recolher" : "Clique para mostrar"}`
        onClicked: {
            Prefs.aiExpanded = !Prefs.aiExpanded;
            Prefs.save();
        }
    }

    Repeater {
        model: root.agents

        BarItem {
            id: item

            required property var modelData
            readonly property string cls: stream.cls

            shown: root.expanded && stream.text !== ""
            height: root.height
            rich: true
            text: stream.text
            tooltip: stream.tooltip
            fontFamily: Config.appearance.monoFont
            opacity: cls === "syncing" ? 0.6 : 1
            textColor: cls.includes("critical") ? Theme.error : cls.endsWith("-low") ? Theme.success : cls.endsWith("-mid") ? Theme.warning : cls.endsWith("-high") ? Theme.error : Theme.text

            onClicked: Utils.run(`pkill -USR1 -f '[a]i-usage-watch ${modelData.name} '`)

            // Os streams correm sempre (mesmo recolhido), para o ícone e a tooltip estarem certos.
            JsonStream {
                id: stream
                exec: `ai-usage-watch ${item.modelData.name} ${item.modelData.period} -- ${item.modelData.cmd}`
                onTextChanged: root.setState(item.modelData.name, text, cls)
                onClsChanged: root.setState(item.modelData.name, text, cls)
            }
        }
    }
}
