pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Cores da shell. Três origens (escolhidas no menu do HyDE, em Prefs.colorSource):
//
//  - "hyde" (por omissão): as cores que cada tema do HyDE desenhou para a barra — o
//    ~/.cache/hyde/wallbash/bar.css que o HyDE reescreve a cada troca de tema (a partir do
//    waybar.theme do tema, ou do template waybar.dcol em modo wallbash).
//  - "wallbash": a paleta completa do tema, gerada pelo template
//    ~/.config/hyde/wallbash/always/quickshell.dcol.
//  - "wallpaper": as cores extraídas do wallpaper atual (~/.cache/hyde/wall.dcol).
//
// Todas as fontes são vigiadas: ao mudar de tema ou de wallpaper, as cores transitam sozinhas.
Singleton {
    id: root

    // Paleta atual do HyDE usada quando nenhum ficheiro existe (Catppuccin Macchiato).
    readonly property var fallbackCss: ({
            "main-bg": "#181926",
            "main-fg": "#cad3f5",
            "wb-act-bg": "#c6a0f6",
            "wb-act-fg": "#363a4f",
            "wb-hvr-bg": "#cad3f5",
            "wb-hvr-fg": "#363a4f"
        })

    property var themeCss: fallbackCss
    property var wallbashPalette: null
    property var wallPalette: null

    readonly property string source: Prefs.colorSource === "wallpaper" && wallPalette ? "wallpaper" : Prefs.colorSource === "wallbash" && wallbashPalette ? "wallbash" : "hyde"
    readonly property var targetRoles: ensureReadable(source === "wallpaper" ? paletteRoles(wallPalette) : source === "wallbash" ? paletteRoles(wallbashPalette) : cssRoles(themeCss))

    // Cada cor é uma mistura entre as cores anteriores e as novas, controlada por `progress`:
    // uma única animação faz a transição de todas (muitos Behavior num singleton rebentam o Qt).
    property var fromRoles: cssRoles(fallbackCss)
    property var toRoles: cssRoles(fallbackCss)
    property real progress: 1

    readonly property bool dark: luminance(surface) < 0.5

    // Papéis semânticos (nomes ao estilo Material 3).
    readonly property color surface: mix("surface")
    readonly property color surfaceContainer: mix("surfaceContainer")
    readonly property color surfaceContainerHigh: mix("surfaceContainerHigh")
    readonly property color surfaceContainerHighest: mix("surfaceContainerHighest")
    readonly property color text: mix("text")
    readonly property color textDim: mix("textDim")
    readonly property color textFaint: mix("textFaint")
    readonly property color outline: mix("outline")
    readonly property color outlineVariant: mix("outlineVariant")
    readonly property color primary: mix("primary")
    readonly property color onPrimary: mix("onPrimary")
    readonly property color primaryContainer: mix("primaryContainer")
    readonly property color onPrimaryContainer: mix("onPrimaryContainer")
    readonly property color secondary: mix("secondary")
    readonly property color tertiary: mix("tertiary")
    // Cores de estado: base fixa, ajustada para se lerem sobre o fundo do tema (claro ou escuro).
    readonly property color error: readable("#f38ba8", surface, 3)
    readonly property color warning: readable("#f9e2af", surface, 3)
    readonly property color success: readable("#a6e3a1", surface, 3)

    // Camadas de estado (hover/press) por cima de qualquer superfície.
    readonly property color hover: Qt.alpha(text, 0.08)
    readonly property color pressed: Qt.alpha(text, 0.14)

    function alpha(color, a) {
        return Qt.alpha(color, a);
    }

    function luminance(c) {
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    }

    // --- Contraste (WCAG 2) -------------------------------------------------------------------
    // Os temas do HyDE nem sempre garantem contraste entre o texto e o fundo (sobretudo os claros),
    // e as ilhas da barra podem ter um fundo diferente do do tema. Todas as cores de texto e de
    // ícones passam por readable(), que as escurece ou clareia o mínimo necessário para se lerem.

    function relativeLuminance(c) {
        c = Qt.color(c);
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }

    function contrast(a, b) {
        const la = relativeLuminance(a), lb = relativeLuminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Devolve `fg` se já tiver o contraste mínimo com `bg`; senão aproxima-o do preto ou do branco
    // (o que der mais contraste com o fundo) até chegar lá, mantendo o tom o mais possível.
    function readable(fg, bg, minRatio) {
        fg = Qt.color(fg);
        bg = Qt.color(bg);
        const ratio = minRatio ?? 4.5;
        if (contrast(fg, bg) >= ratio)
            return fg;
        const target = contrast("#000000", bg) > contrast("#ffffff", bg) ? "#000000" : "#ffffff";
        for (let t = 0.1; t < 1; t += 0.1) {
            const c = blend(fg, target, t);
            if (contrast(c, bg) >= ratio)
                return Qt.rgba(c.r, c.g, c.b, fg.a);
        }
        return Qt.color(target);
    }

    // Passagem final de legibilidade sobre os papéis de um tema.
    function ensureReadable(r) {
        r.text = readable(r.text, r.surface, 4.5);
        r.textDim = readable(r.textDim, r.surface, 3.5);
        r.textFaint = readable(r.textFaint, r.surface, 2.6);
        r.primary = readable(r.primary, r.surface, 3);
        r.onPrimary = readable(r.onPrimary, r.primary, 4.5);
        r.onPrimaryContainer = readable(r.onPrimaryContainer, r.primaryContainer, 4.5);
        r.secondary = readable(r.secondary, r.surface, 3);
        r.tertiary = readable(r.tertiary, r.surface, 3);
        return r;
    }

    // Mistura linear de duas cores (t = 0 → a, t = 1 → b), sempre opaca.
    function blend(a, b, t) {
        a = Qt.color(a);
        b = Qt.color(b);
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    // Cor do theme.css com transparência (ex.: rgba(…, 0.4) no modo wallbash) aplicada sobre o
    // fundo, para obter a cor que realmente se vê.
    function flatten(c, over) {
        c = Qt.color(c);
        return c.a >= 0.99 ? Qt.rgba(c.r, c.g, c.b, 1) : blend(over, Qt.rgba(c.r, c.g, c.b, 1), c.a);
    }

    // O Qt não percebe "rgba(r, g, b, a)" com componentes 0..255; converte-se aqui.
    function cssColor(v) {
        const m = /^rgba?\(([^)]*)\)$/.exec(String(v).trim());
        if (!m)
            return Qt.color(v);
        const p = m[1].split(",").map(s => parseFloat(s));
        return Qt.rgba(p[0] / 255, p[1] / 255, p[2] / 255, p.length > 3 ? p[3] : 1);
    }

    // O tema do HyDE só define as cores principais da barra; os tons intermédios derivam delas.
    function cssRoles(css) {
        const get = k => cssColor(css[k] ?? fallbackCss[k]);
        const surface = flatten(get("main-bg"), "#000000");
        const text = flatten(get("main-fg"), surface);
        const primary = flatten(get("wb-act-bg"), surface);
        const onPrimary = flatten(get("wb-act-fg"), primary);
        const hoverBg = flatten(get("wb-hvr-bg"), surface);
        return {
            "surface": surface,
            "surfaceContainer": blend(surface, text, 0.06),
            "surfaceContainerHigh": blend(surface, text, 0.1),
            "surfaceContainerHighest": blend(surface, text, 0.16),
            "text": text,
            "textDim": blend(text, surface, 0.22),
            "textFaint": blend(text, surface, 0.38),
            "outline": blend(surface, text, 0.32),
            "outlineVariant": blend(surface, text, 0.18),
            "primary": primary,
            "onPrimary": onPrimary,
            "primaryContainer": blend(surface, primary, 0.32),
            "onPrimaryContainer": blend(text, primary, 0.15),
            "secondary": hoverBg,
            "tertiary": blend(primary, text, 0.35)
        };
    }

    // Paleta do wallbash: 4 grupos (pry1..4, do dominante ao acento), cada um com um texto de
    // contraste (txtN) e 9 tons (NxaM) que vão do tom do fundo (xa1) ao do texto (xa9), tanto em
    // modo escuro como claro.
    function paletteRoles(p) {
        const get = k => Qt.color(p[k] ?? "#ff00ff");
        return {
            "surface": get("pry1"),
            "surfaceContainer": get("1xa1"),
            "surfaceContainerHigh": get("1xa2"),
            "surfaceContainerHighest": get("1xa3"),
            "text": get("txt1"),
            "textDim": get("1xa7"),
            "textFaint": get("1xa6"),
            "outline": get("1xa4"),
            "outlineVariant": get("1xa3"),
            "primary": get("4xa7"),
            "onPrimary": get("4xa1"),
            "primaryContainer": get("4xa3"),
            "onPrimaryContainer": get("4xa9"),
            "secondary": get("2xa7"),
            "tertiary": get("3xa7")
        };
    }

    function mix(role) {
        const a = fromRoles[role], b = toRoles[role], t = progress;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    // Novas cores: parte das que estão no ecrã agora (mesmo a meio de outra transição).
    onTargetRolesChanged: {
        const current = {};
        for (const role in targetRoles)
            current[role] = root[role];
        fromRoles = current;
        toRoles = targetRoles;
        progress = 0;
        transition.restart();
    }

    function setColorSource(source) {
        Prefs.colorSource = source;
        Prefs.save();
    }

    NumberAnimation {
        id: transition
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Anim.slow
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.standard
    }

    // Cores da barra do tema do HyDE (@define-color nome valor;).
    FileView {
        path: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/hyde/wallbash/bar.css`
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
            if (out["main-bg"])
                root.themeCss = out;
        }
    }

    FileView {
        path: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/hyde/wallbash/quickshell.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.wallbashPalette = JSON.parse(text());
            } catch (e) {
                // O wallbash escreve o ficheiro de uma vez; um JSON a meio só acontece por instantes.
            }
        }
        onLoadFailed: root.wallbashPalette = null
    }

    // Formato: dcol_pry1="23162D", dcol_1xa1="402952", dcol_mode="dark"…
    FileView {
        path: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/hyde/wall.dcol`
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
            root.wallPalette = p.pry1 ? p : null;
        }
        onLoadFailed: root.wallPalette = null
    }
}
