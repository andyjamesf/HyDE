pragma Singleton
import QtQuick
import Quickshell

// The Settings screen (island mode "settings"). Values changed there are stored as overrides in
// <XDG_STATE_HOME>/morphing-island/prefs.json (services/Prefs.qml) and win over the defaults in the
// other config files; "Reset to defaults" removes them (the file defaults apply again).
Singleton {
    // Width of the screen in pixels. Default 480.
    readonly property int width: 480
    // Maximum height in pixels; the body scrolls beyond it. Default 620.
    readonly property int maxHeight: 620

    // Slider ranges.
    // Pill height (Pill.height) in pixels. Defaults 30–51.
    readonly property int barHeightMin: 30
    readonly property int barHeightMax: 51
    // Base font size (Appearance.fontSize) in pixels. Defaults 11–18.
    readonly property int fontSizeMin: 11
    readonly property int fontSizeMax: 18
    // Animation speed multiplier (Animations.speed). Defaults 0.5–2, step 0.1.
    readonly property real speedMin: 0.5
    readonly property real speedMax: 2
    readonly property real speedStep: 0.1

    // Changes are written to prefs.json after this pause (sliders apply live, the file is written
    // once the drag settles). Milliseconds, default 300.
    readonly property int saveDebounceMs: 300

    // Prefs keys removed by "Reset to defaults". Theme and wallpaper are left alone (they have their
    // own pickers).
    readonly property var resetKeys: ["pill.height", "appearance.fontSize", "pill.hoverExpand", "notifications.peaceMode", "animations.enabled", "animations.speed"]
}
