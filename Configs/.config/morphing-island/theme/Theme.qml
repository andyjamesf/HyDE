pragma Singleton
import QtQuick
import Quickshell
import qs.config

// The island's colour roles. No component uses hand-written colours: everything comes from here,
// so the same code serves dark, light and e-ink themes.
//
// The scheme comes from ThemeConfig.name (fixed or dynamic, see Palettes). Before reaching the
// roles it goes through a readability check (WCAG): text keeps a contrast ≥ ThemeConfig.textContrast
// with the background and the accent ≥ ThemeConfig.accentContrast, moving them towards black or
// white as little as needed. Opacity, border, shadow and transition: config/ThemeConfig.qml.
//
// Transition: each role is a mix between the previous colours (fromRoles) and the new ones
// (toRoles), driven by a single `progress`. One animation handles all colours (many Behaviors in
// a singleton crash Qt).
Singleton {
    id: root

    readonly property var palette: Palettes.find(ThemeConfig.name)
    readonly property string kind: palette.kind
    readonly property bool eink: kind === "eink"
    readonly property bool dark: kind === "dark" || (eink && relativeLuminance(palette.background) < 0.5)

    // Final roles of the current scheme (target of the transition).
    readonly property var targetRoles: roles(resolve(palette))

    property var fromRoles: null
    property var toRoles: null
    property real progress: 1
    // In the first moments (preferences still loading) colours change without animation.
    property bool ready: false

    readonly property color background: mix("background")
    readonly property color surface: mix("surface")
    readonly property color foreground: mix("foreground")
    readonly property color accent: mix("accent")
    readonly property color accentContent: mix("accentContent")
    readonly property color dim: mix("dim")
    readonly property color faint: mix("faint")
    readonly property color border: mix("border")
    readonly property color shadow: mix("shadow")
    readonly property color icon: mix("icon")
    readonly property color danger: mix("danger")
    readonly property color hover: mix("hover")
    readonly property color pressed: mix("pressed")
    readonly property real islandOpacity: eink ? 1 : ThemeConfig.islandOpacity

    // Base colours (already readable) of any scheme, without applying it: for the picker swatches.
    // Returns { name, kind, available, background, surface, foreground, accent, accentContent }.
    function preview(name) {
        const p = Palettes.find(name);
        const b = resolve(p);
        b.name = p.name;
        b.available = p.available ?? true;
        b.accentContent = onColor(b.accent);
        return b;
    }

    // Scheme → base colours with the minimum contrast guaranteed.
    function resolve(p) {
        const bg = Qt.color(p.background);
        return {
            kind: p.kind,
            background: bg,
            surface: Qt.color(p.surface),
            foreground: readable(p.foreground, bg, ThemeConfig.textContrast),
            accent: readable(p.accent, bg, ThemeConfig.accentContrast),
            danger: p.danger ? Qt.color(p.danger) : null
        };
    }

    // Base colours → all roles.
    function roles(b) {
        const eink = b.kind === "eink";
        const dark = b.kind === "dark" || (eink && relativeLuminance(b.background) < 0.5);
        const fg = b.foreground, bg = b.background;
        return {
            background: bg,
            surface: b.surface,
            foreground: fg,
            accent: b.accent,
            accentContent: onColor(b.accent),
            dim: readable(blend(fg, bg, 0.4), bg, ThemeConfig.accentContrast),
            faint: blend(fg, bg, 0.62),
            border: eink ? fg : Qt.alpha(fg, dark ? ThemeConfig.borderAlphaDark : ThemeConfig.borderAlphaLight),
            shadow: eink ? Qt.rgba(0, 0, 0, 0) : Qt.rgba(0, 0, 0, dark ? ThemeConfig.shadowAlphaDark : ThemeConfig.shadowAlphaLight),
            icon: fg,
            danger: eink ? fg : readable(b.danger ?? (dark ? Palettes.dangerDark : Palettes.dangerLight), bg, ThemeConfig.accentContrast),
            hover: Qt.alpha(fg, eink ? 0.12 : 0.08),
            pressed: Qt.alpha(fg, eink ? 0.2 : 0.14)
        };
    }

    function mix(role) {
        const b = (toRoles ?? targetRoles)[role];
        const a = fromRoles ? fromRoles[role] : b;
        const t = progress;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    // New colours: start from the ones on screen now (even midway through another transition). If
    // nothing changed (e.g. the wallpaper changed but the theme is fixed), there is no transition.
    onTargetRolesChanged: {
        const next = targetRoles;
        if (toRoles && Object.keys(next).every(k => Qt.colorEqual(next[k], toRoles[k])))
            return;
        const current = {};
        for (const role in next)
            current[role] = root[role];
        transition.stop();
        fromRoles = current;
        toRoles = next;
        if (Animations.enabled && ready) {
            progress = 0;
            transition.start();
        } else {
            progress = 1;
        }
    }

    NumberAnimation {
        id: transition
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: ThemeConfig.transitionMs
        easing.type: Easing.InOutCubic
    }

    Timer {
        running: true
        interval: 600
        onTriggered: root.ready = true
    }

    // --- Contrast (WCAG 2) ------------------------------------------------------------------------

    function blend(a, b, t) {
        a = Qt.color(a);
        b = Qt.color(b);
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function relativeLuminance(c) {
        c = Qt.color(c);
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }

    function contrast(a, b) {
        const la = relativeLuminance(a), lb = relativeLuminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Black or white, whichever reads better on top of `c`.
    function onColor(c) {
        return contrast(c, Palettes.black) > contrast(c, Palettes.white) ? Palettes.black : Palettes.white;
    }

    // Returns `fg` if it already has the minimum contrast with `bg`; otherwise moves it towards black
    // or white (whichever contrasts more with the background) until it gets there, keeping the hue.
    function readable(fg, bg, minRatio) {
        fg = Qt.color(fg);
        bg = Qt.color(bg);
        const ratio = minRatio ?? ThemeConfig.textContrast;
        if (contrast(fg, bg) >= ratio)
            return fg;
        const target = onColor(bg);
        for (let t = 0.05; t < 1; t += 0.05) {
            const c = blend(fg, target, t);
            if (contrast(c, bg) >= ratio)
                return Qt.rgba(c.r, c.g, c.b, fg.a);
        }
        return Qt.color(target);
    }
}
