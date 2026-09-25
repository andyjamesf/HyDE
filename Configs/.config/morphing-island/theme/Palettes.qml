pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The island's colour schemes (palettes). Each one defines only the base roles; Theme derives the
// rest (and guarantees the minimum contrast). kind: "dark" | "light" | "eink" (e-ink has no
// shadows, transparency nor gradients). This is the only file with hand-written colours.
//
// Adding a palette: append an entry to `list` below, in its kind's section:
//   { name: "My Theme", kind: "dark", background: "#101010", surface: "#1a1a1a",
//     foreground: "#eeeeee", accent: "#ff8800", danger: "#ff5555" /* optional */ }
// It shows up in Settings → Theme right away (live reload).
//
// There are two dynamic schemes, always first in the list, that update by themselves:
//  - "Wallpaper": colours of the current wallpaper. If ~/.cache/wallust/colors.json exists (a
//    wallust template in pywal's format: { special: { background, foreground }, colors: { color0…15 } }),
//    it takes priority; otherwise ~/.cache/hyde/wall.dcol is used, which HyDE's wallbash rewrites on
//    every wallpaper change (dcol_pry1 dominant, dcol_txt1 text, dcol_1xa1…9 shades, dcol_4xa7
//    accent, dcol_mode dark/light).
//  - "HyDE": the bar colours of the current HyDE theme (~/.config/waybar/theme.css, @define-color
//    main-bg, main-fg, wb-act-bg…), which HyDE rewrites on every theme change.
// While the source does not exist, the dynamic scheme uses the colours of the first fixed scheme
// and is marked unavailable (available: false).
Singleton {
    id: root

    readonly property color black: "#000000"
    readonly property color white: "#ffffff"
    // Default error red (a scheme may bring its own in `danger`).
    readonly property color dangerDark: "#ff6b6b"
    readonly property color dangerLight: "#c62828"

    readonly property var list: [
        // --- Dark ---
        {
            name: "Midnight",
            kind: "dark",
            background: "#14151c",
            surface: "#1e2029",
            foreground: "#e6e8f0",
            accent: "#8ab4ff"
        },
        {
            name: "Fjord",
            kind: "dark",
            background: "#2b303b",
            surface: "#353b48",
            foreground: "#e5e9f0",
            accent: "#88c0d0"
        },
        {
            name: "Vampire",
            kind: "dark",
            background: "#1e1f29",
            surface: "#282a36",
            foreground: "#f8f8f2",
            accent: "#bd93f9",
            danger: "#ff5555"
        },
        {
            name: "Ember",
            kind: "dark",
            background: "#1d2021",
            surface: "#282828",
            foreground: "#ebdbb2",
            accent: "#fe8019",
            danger: "#fb4934"
        },
        {
            name: "Mocha",
            kind: "dark",
            background: "#181825",
            surface: "#1e1e2e",
            foreground: "#cdd6f4",
            accent: "#cba6f7",
            danger: "#f38ba8"
        },
        {
            name: "Neon Tokyo",
            kind: "dark",
            background: "#16161e",
            surface: "#1f2335",
            foreground: "#c0caf5",
            accent: "#7aa2f7",
            danger: "#f7768e"
        },
        {
            name: "Rosewood",
            kind: "dark",
            background: "#191724",
            surface: "#1f1d2e",
            foreground: "#e0def4",
            accent: "#ebbcba",
            danger: "#eb6f92"
        },
        {
            name: "Forest",
            kind: "dark",
            background: "#232a2e",
            surface: "#2d353b",
            foreground: "#d3c6aa",
            accent: "#a7c080",
            danger: "#e67e80"
        },
        {
            name: "Ocean",
            kind: "dark",
            background: "#0b1622",
            surface: "#13233a",
            foreground: "#d6e6f5",
            accent: "#4fc3f7"
        },
        {
            name: "Graphite",
            kind: "dark",
            background: "#161616",
            surface: "#222222",
            foreground: "#e4e4e4",
            accent: "#a3b8cc"
        },
        // --- Light ---
        {
            name: "Paper",
            kind: "light",
            background: "#f7f6f2",
            surface: "#ecebe6",
            foreground: "#1f1f1f",
            accent: "#3a6df0"
        },
        {
            name: "Latte",
            kind: "light",
            background: "#eff1f5",
            surface: "#e6e9ef",
            foreground: "#4c4f69",
            accent: "#8839ef",
            danger: "#d20f39"
        },
        {
            name: "Sakura",
            kind: "light",
            background: "#fdf2f4",
            surface: "#f7e1e6",
            foreground: "#3d2930",
            accent: "#d6557a"
        },
        {
            name: "Sand",
            kind: "light",
            background: "#f4ecd8",
            surface: "#eadfc4",
            foreground: "#3b3226",
            accent: "#b5651d"
        },
        {
            name: "Mint",
            kind: "light",
            background: "#eef8f3",
            surface: "#dcefe5",
            foreground: "#1f3a2e",
            accent: "#1f9d6b"
        },
        {
            name: "Sky",
            kind: "light",
            background: "#eef5fc",
            surface: "#dde9f7",
            foreground: "#1b2b40",
            accent: "#2b7de9"
        },
        // --- E-ink (black and white only) ---
        {
            name: "E-Ink",
            kind: "eink",
            background: "#ffffff",
            surface: "#ffffff",
            foreground: "#000000",
            accent: "#000000"
        },
        {
            name: "E-Ink Dark",
            kind: "eink",
            background: "#000000",
            surface: "#000000",
            foreground: "#ffffff",
            accent: "#ffffff"
        }
    ]

    // Colours read from the dynamic sources ({ kind, background, surface, foreground, accent } or null).
    property var wallust: null
    property var wallbash: null
    property var hyde: null
    readonly property var wallpaper: wallust ?? wallbash
    // Source of the "Wallpaper" scheme ("wallust", "wallbash" or "" if none exists).
    readonly property string wallpaperSource: wallust ? "wallust" : wallbash ? "wallbash" : ""

    // Names of the dynamic schemes (fixed: the picker builds its grid from names only).
    readonly property var dynamicNames: ["Wallpaper", "HyDE"]
    readonly property var dynamicList: [entry(dynamicNames[0], wallpaper), entry(dynamicNames[1], hyde)]
    // All schemes in picker order: dynamic, dark, light, e-ink.
    readonly property var all: dynamicList.concat(list)

    function find(name) {
        return all.find(p => p.name === name) ?? list[0];
    }

    function entry(name, src) {
        const base = src ?? list[0];
        return {
            name: name,
            kind: base.kind,
            background: base.background,
            surface: base.surface,
            foreground: base.foreground,
            accent: base.accent,
            dynamic: true,
            available: !!src
        };
    }

    // --- Colour utilities (only to interpret the dynamic sources) ---------------------------------

    function blend(a, b, t) {
        a = Qt.color(a);
        b = Qt.color(b);
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    // Approximate lightness (enough to decide whether a background is light or dark).
    function lightness(c) {
        c = Qt.color(c);
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // Approximate saturation (difference between the strongest and weakest channel).
    function chroma(c) {
        c = Qt.color(c);
        return Math.max(c.r, c.g, c.b) - Math.min(c.r, c.g, c.b);
    }

    // Qt does not understand "rgba(r, g, b, a)" with 0..255 components; converted here.
    function cssColor(v) {
        const m = /^rgba?\(([^)]*)\)$/.exec(String(v).trim());
        if (!m)
            return Qt.color(String(v).trim());
        const p = m[1].split(",").map(s => parseFloat(s));
        return Qt.rgba(p[0] / 255, p[1] / 255, p[2] / 255, p.length > 3 ? p[3] : 1);
    }

    // Colour with transparency applied over the background: the colour actually seen.
    function flatten(c, over) {
        c = Qt.color(c);
        return c.a >= 0.99 ? Qt.rgba(c.r, c.g, c.b, 1) : blend(over, Qt.rgba(c.r, c.g, c.b, 1), c.a);
    }

    // Among several colours, the most saturated (a good accent candidate).
    function mostChromatic(colors) {
        return colors.reduce((best, c) => chroma(c) > chroma(best) ? c : best, colors[0]);
    }

    function fromCss(css) {
        const bg = flatten(cssColor(css["main-bg"]), black);
        const fg = flatten(cssColor(css["main-fg"] ?? white), bg);
        const cands = ["wb-act-bg", "wb-hvr-bg", "wb-act-fg", "wb-hvr-fg"].filter(k => css[k] !== undefined).map(k => flatten(cssColor(css[k]), bg));
        // The theme's accent is wb-act-bg; if it is almost grey, the most vivid bar colour is used.
        let accent = cands.length ? cands[0] : fg;
        if (chroma(accent) < 0.12 && cands.length > 1)
            accent = mostChromatic(cands);
        return {
            kind: lightness(bg) < 0.5 ? "dark" : "light",
            background: bg,
            surface: blend(bg, fg, 0.07),
            foreground: fg,
            accent: accent
        };
    }

    function fromDcol(p) {
        const bg = Qt.color(p.pry1);
        const dark = p.mode === "light" ? false : p.mode === "dark" ? true : lightness(bg) < 0.5;
        return {
            kind: dark ? "dark" : "light",
            background: bg,
            surface: p["1xa1"] ? blend(bg, p["1xa1"], 0.5) : bg,
            foreground: Qt.color(p.txt1 ?? (dark ? white : black)),
            accent: Qt.color(p["4xa7"] ?? p["1xa7"] ?? p.txt1 ?? (dark ? white : black))
        };
    }

    function fromWallust(j) {
        const s = j.special ?? {};
        const c = j.colors ?? {};
        const bg = Qt.color(s.background ?? c.color0);
        const fg = Qt.color(s.foreground ?? c.color15 ?? c.color7 ?? (lightness(bg) < 0.5 ? white : black));
        const cands = ["color1", "color2", "color3", "color4", "color5", "color6"].filter(k => c[k]).map(k => Qt.color(c[k]));
        return {
            kind: lightness(bg) < 0.5 ? "dark" : "light",
            background: bg,
            surface: blend(bg, fg, 0.07),
            foreground: fg,
            accent: cands.length ? mostChromatic(cands) : fg
        };
    }

    readonly property string cacheDir: Paths.cacheHome
    readonly property string configDir: Paths.configHome

    // Format: dcol_pry1="23162D", dcol_1xa1="402952", dcol_mode="dark"…
    FileView {
        path: `${root.cacheDir}/hyde/wall.dcol`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const p = {};
            const re = /^dcol_(mode|pry\d|txt\d|\dxa\d)="([^"]*)"/gm;
            const src = text();
            let m;
            while ((m = re.exec(src)) !== null)
                p[m[1]] = m[1] === "mode" ? m[2] : `#${m[2]}`;
            root.wallbash = p.pry1 ? root.fromDcol(p) : null;
        }
        onLoadFailed: root.wallbash = null
    }

    // Optional: only exists if wallust is installed with a colors.json template.
    FileView {
        path: `${root.cacheDir}/wallust/colors.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.wallust = (j.special?.background || j.colors?.color0) ? root.fromWallust(j) : null;
            } catch (e) {
                // File half-written: the previous value stays until the next notification.
            }
        }
        onLoadFailed: root.wallust = null
    }

    // Bar colours of the HyDE theme (@define-color name value;).
    FileView {
        path: `${root.configDir}/waybar/theme.css`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const out = {};
            const re = /@define-color\s+([\w-]+)\s+([^;]+);/g;
            const css = text().replace(/\/\*[\s\S]*?\*\//g, "");
            let m;
            while ((m = re.exec(css)) !== null) {
                const v = m[2].trim();
                const value = v.startsWith("@") ? out[v.slice(1)] : v;
                if (value !== undefined)
                    out[m[1]] = value;
            }
            root.hyde = out["main-bg"] ? root.fromCss(out) : null;
        }
        onLoadFailed: root.hyde = null
    }
}
