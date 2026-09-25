pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Colours and surface look. The palettes themselves live in theme/Palettes.qml; the chosen one is
// stored as the Prefs key "theme.name" (Settings → Theme). (Named ThemeConfig because
// theme/Theme.qml computes the colour roles.)
Singleton {
    // Palette used until one is chosen (a name from theme/Palettes.qml, e.g. "Midnight", "Wallpaper",
    // "HyDE"). Default "Midnight".
    readonly property string defaultTheme: "Midnight"
    // Effective palette name (the user's choice, or defaultTheme).
    readonly property string name: Prefs.get("theme.name", defaultTheme)
    // Opacity of the island background (e-ink palettes are always opaque). 0–1, default 0.94.
    readonly property real islandOpacity: 0.94
    // Border alpha over the foreground colour, on dark / light palettes. 0–1, defaults 0.1 / 0.14.
    readonly property real borderAlphaDark: 0.1
    readonly property real borderAlphaLight: 0.14
    // Shadow alpha (black), on dark / light palettes. 0–1, defaults 0.45 / 0.18.
    readonly property real shadowAlphaDark: 0.45
    readonly property real shadowAlphaLight: 0.18
    // Shadow blur (MultiEffect.shadowBlur). 0–1, default 0.7.
    readonly property real shadowBlur: 0.7
    // Shadow vertical offset in pixels. Default 3.
    readonly property real shadowOffsetY: 3
    // Minimum WCAG contrast of text / accent against the background; colours are nudged towards
    // black or white until they reach it. Defaults 4.5 / 3.
    readonly property real textContrast: 4.5
    readonly property real accentContrast: 3
    // Cross-fade between palettes when the theme changes. Milliseconds, default 420.
    readonly property int transitionMs: 420

    function setTheme(name) {
        Prefs.set("theme.name", name);
    }
}
