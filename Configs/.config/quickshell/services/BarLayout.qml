pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Layout efetivo da barra. Os presets estão em config/layouts.json (podem acrescentar-se outros);
// cada um define o estilo, as dimensões e que widgets aparecem em cada secção.
//
// Qual se usa, por ordem:
//   1. o escolhido no menu do HyDE / por IPC (`qs ipc call bar layout <nome>`, `next`, `prev`),
//      guardado nas Prefs;
//   2. o "layout" do config.json.
// Ao mudar de tema no HyDE, se o config.json tiver um layout para esse tema em "themeLayouts",
// passa a ser esse. O arredondamento das ilhas segue o `decoration:rounding` do Hyprland, que
// cada tema do HyDE define — a barra acompanha o aspeto das janelas.
Singleton {
    id: root

    property var presets: ({})
    readonly property var names: Object.keys(presets)
    readonly property string current: presets[Prefs.layout] ? Prefs.layout : presets[Config.bar.layout] ? Config.bar.layout : names[0] ?? ""
    readonly property var preset: presets[current] ?? ({})

    property string hydeTheme: ""
    property int hyprRounding: 10

    readonly property string style: preset.style ?? "islands"
    readonly property bool islands: style === "islands"
    readonly property string position: preset.position ?? Config.bar.position
    readonly property bool atTop: position !== "bottom"
    // Altura escolhida no menu/IPC, ou a do layout. O texto, os ícones e o raio acompanham-na.
    readonly property int layoutHeight: preset.height ?? 28
    readonly property int height: Prefs.barHeight > 0 ? Prefs.barHeight : layoutHeight
    readonly property int minHeight: 16
    readonly property int maxHeight: 40
    readonly property var heights: [
        {
            label: "Short",
            value: 19
        },
        {
            label: "Normal",
            value: 23
        },
        {
            label: "Tall",
            value: 27
        },
        {
            label: "Extra tall",
            value: 32
        }
    ]
    readonly property int margin: islands ? (preset.margin ?? 4) : 0
    readonly property int spacing: preset.spacing ?? 4
    readonly property int radius: Math.min(preset.radius ?? hyprRounding, Math.floor(height / 2))
    readonly property real opacity: Prefs.pillOpacity >= 0 ? Prefs.pillOpacity : preset.opacity ?? Config.bar.opacity

    // Fundo das ilhas. Todas as opções saem das cores do tema, por isso mudam com ele.
    readonly property var pillStyles: [
        {
            id: "surface",
            label: "Theme background"
        },
        {
            id: "tint",
            label: "Accent tint"
        },
        {
            id: "container",
            label: "Raised"
        },
        {
            id: "accent",
            label: "Accent color"
        },
        {
            id: "glass",
            label: "Glass"
        },
        {
            id: "outline",
            label: "Outline only"
        }
    ]
    readonly property string pillStyle: Prefs.pillStyle || preset.pillStyle || Config.bar.pillStyle
    readonly property color pillColor: {
        const a = opacity;
        switch (pillStyle) {
        case "surface":
            return Theme.alpha(Theme.surface, a);
        case "tint":
            return Theme.alpha(Qt.tint(Theme.surface, Theme.alpha(Theme.primary, 0.24)), a);
        case "container":
            return Theme.alpha(Theme.surfaceContainerHighest, a);
        case "accent":
            return Theme.alpha(Theme.primaryContainer, a);
        case "glass":
            return Theme.alpha(Theme.surface, Math.min(a, 0.4));
        case "outline":
            return "transparent";
        default:
            // Cor fixa escrita no config.json ("#rrggbb").
            return /^#[0-9a-fA-F]{6,8}$/.test(pillStyle) ? Theme.alpha(pillStyle, a) : Theme.alpha(Theme.surface, a);
        }
    }
    readonly property color pillBorder: pillStyle === "outline" ? Theme.alpha(Theme.primary, 0.7) : pillStyle === "glass" ? Theme.alpha(Theme.text, 0.18) : Theme.alpha(Theme.outlineVariant, 0.5)

    // Cor opaca que se vê por trás do texto das ilhas (para garantir contraste). Nos estilos
    // transparentes não se sabe o que está por trás (o wallpaper); usa-se o fundo do tema.
    readonly property color pillBase: {
        const c = Qt.color(pillColor);
        return c.a < 0.5 ? Theme.surface : Qt.rgba(c.r, c.g, c.b, 1);
    }

    // Cor legível sobre as ilhas: texto 4.5:1, ícones e elementos gráficos 3:1.
    function readable(color, minRatio) {
        return Theme.readable(color, pillBase, minRatio ?? 4.5);
    }

    function setPillStyle(style) {
        Prefs.pillStyle = style;
        Prefs.save();
    }

    // 0 volta à altura do layout.
    function setHeight(value) {
        Prefs.barHeight = value > 0 ? Math.max(minHeight, Math.min(maxHeight, Math.round(value))) : 0;
        Prefs.save();
    }

    function adjustHeight(step) {
        setHeight(height + step);
    }

    function setPillOpacity(value) {
        Prefs.pillOpacity = value;
        Prefs.save();
    }
    // Texto e ícones acompanham a altura, mas nunca ficam ilegíveis.
    readonly property int fontSize: preset.fontSize ?? Math.max(11, Math.min(Config.appearance.fontSize, Math.round(height * 0.46)))
    readonly property int iconSize: preset.iconSize ?? Math.max(14, Math.min(Config.appearance.iconSize, Math.round(height * 0.64)))
    readonly property var left: preset.left ?? []
    readonly property var center: preset.center ?? []
    readonly property var right: preset.right ?? []

    function select(name) {
        if (!presets[name]) {
            console.warn(`unknown layout: "${name}"`);
            return;
        }
        Prefs.layout = name;
        Prefs.save();
        Utils.run(`notify-send -a "Quickshell" -r 91 -t 1500 -h int:transient:1 -i preferences-desktop "Bar layout" "${presets[name].label ?? name}"`);
    }

    function cycle(step) {
        const i = names.indexOf(current);
        select(names[(i + step + names.length) % names.length]);
    }

    FileView {
        path: Quickshell.shellPath("config/layouts.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.presets = JSON.parse(text());
            } catch (e) {
                console.warn("invalid layouts.json:", e);
            }
        }
    }

    // Tema atual do HyDE (reescrito a cada troca de tema).
    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/hyde/staterc`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const m = /^HYDE_THEME="?([^"\n]*)"?/m.exec(text());
            if (m && m[1] !== root.hydeTheme)
                root.hydeTheme = m[1];
        }
    }

    onHydeThemeChanged: {
        const mapped = Config.bar.themeLayouts[hydeTheme];
        if (mapped && mapped !== current)
            select(mapped);
        rounding.running = true;
    }

    // O tema aplica o rounding no Hyprland logo a seguir a mudar o staterc; lê-se com folga.
    Process {
        id: rounding
        command: ["sh", "-c", "sleep 1; hyprctl getoption decoration:rounding -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.hyprRounding = JSON.parse(text).int;
                } catch (e) {}
            }
        }
    }
}
