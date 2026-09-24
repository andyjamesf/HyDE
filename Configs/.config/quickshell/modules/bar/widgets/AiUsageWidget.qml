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

    // "<span foreground='#c'>G</span> 61% <span …>G</span> 3h06m" → [{glyph, color, text}, …]:
    // cada ícone com o valor que se lhe segue.
    function parse(markup) {
        const out = [];
        const re = /<span([^>]*)>([^<]*)<\/span>|([^<]+)/g;
        let m;
        while ((m = re.exec(markup || "")) !== null) {
            if (m[3] !== undefined) {
                const t = m[3].trim();
                if (!t)
                    continue;
                if (out.length && out[out.length - 1].text === "")
                    out[out.length - 1].text = t;
                else
                    out.push({
                        glyph: "",
                        color: "",
                        text: t
                    });
            } else {
                const c = /(?:foreground|fgcolor|color)=['"]([^'"]+)['"]/.exec(m[1]);
                out.push({
                    glyph: m[2].trim(),
                    color: c ? c[1] : "",
                    text: ""
                });
            }
        }
        return out;
    }

    function setState(name, text, cls) {
        const s = Object.assign({}, states);
        s[name] = {
            // Ícone e valor separados por espaços (colados, o glifo tapava o número na tooltip).
            text: root.parse(text).map(g => [g.glyph, g.text].filter(x => x).join("&nbsp;&nbsp;")).join("&nbsp;&nbsp;&nbsp;&nbsp;"),
            cls: cls
        };
        states = s;
    }

    BarItem {
        id: toggle
        height: root.height
        icon: "smart_toy"
        ipcName: "aiUsage"
        iconFill: root.expanded ? 1 : 0
        iconColor: root.worst === "high" ? Theme.error : root.worst === "mid" ? Theme.warning : Theme.primary
        active: root.expanded
        tooltip: root.agents.map(a => `<b>${a.label}</b>&nbsp;&nbsp;${root.states[a.name]?.text || "…"}`).join("\n") + `\n\n${root.expanded ? "Click to collapse" : "Click to expand"}`
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

            // Os scripts escrevem "<span …>ícone</span> valor"; o ícone (Nerd Font) é desenhado à
            // parte, numa caixa própria: dentro do texto em Inter, o glifo sobrepunha-se aos números.
            readonly property var segments: root.parse(stream.text)

            shown: root.expanded && stream.text !== ""
            height: root.height
            padding: Math.round(BarLayout.height * 0.3)
            tooltip: stream.tooltip
            opacity: cls === "syncing" ? 0.6 : 1
            textColor: cls.includes("critical") ? Theme.error : cls.endsWith("-low") ? Theme.success : cls.endsWith("-mid") ? Theme.warning : cls.endsWith("-high") ? Theme.error : Theme.text

            onClicked: Utils.run(`pkill -USR1 -f '[a]i-usage-watch ${modelData.name} '`)

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(BarLayout.height * 0.3)

                Repeater {
                    model: item.segments

                    Row {
                        id: seg

                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(BarLayout.height * 0.22)

                        StyledText {
                            visible: seg.modelData.glyph !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: BarLayout.iconSize
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideNone
                            text: seg.modelData.glyph
                            font.family: Config.appearance.monoFont
                            font.pixelSize: Math.round(BarLayout.iconSize * 0.85)
                            color: BarLayout.readable(seg.modelData.color || item.textColor, 3)
                        }

                        StyledText {
                            visible: seg.modelData.text !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideNone
                            text: seg.modelData.text
                            font.pixelSize: BarLayout.fontSize
                            color: BarLayout.readable(item.textColor, 4.5)
                        }
                    }
                }
            }

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
