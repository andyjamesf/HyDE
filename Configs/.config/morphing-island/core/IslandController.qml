pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// The island's state machine. `mode` is what the island on the active screen shows on top of the
// base mode; the base mode (clock or expanded) belongs to each screen and depends on hover and pin.
Singleton {
    id: root

    // Current surface or transient ("" = none: each island shows its base mode).
    property string mode: ""
    // Screen where `mode` appears (the one that had the focus when it opened).
    property string screen: ""
    // Pinned expanded island (click on empty space).
    property bool pinned: false
    // Data of the current transient (OSD value, notification…).
    property var payload: null
    // IPC tests: pretends the pointer is over the island on the active screen.
    property bool forceHover: false
    // Transient paused (hover over the island).
    property bool held: false

    // Countdown of the current transient (ms). Time only advances while it is visible and not
    // hovered, so leaving the hover resumes where it stopped instead of starting over.
    property int transientDuration: 0
    property real transientElapsed: 0
    // 0 → just appeared; 1 → about to close (for the countdown indicator).
    readonly property real transientProgress: transientDuration > 0 ? Math.min(1, transientElapsed / transientDuration) : 0

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? ""

    // Mode the island of a screen should show.
    function modeFor(screenName, hovered) {
        if (mode !== "" && screenName === screen)
            return mode;
        return pinned || (hovered && Pill.hoverExpand) ? IslandState.expanded : IslandState.clock;
    }

    // Surface Esc returns to (e.g. theme or wallpaper opened from the settings).
    property string returnMode: ""

    function open(m) {
        if (mode === m && screen === focusedScreen) {
            close();
            return;
        }
        returnMode = mode === IslandState.settings && (m === IslandState.theme || m === IslandState.wallpaper) ? IslandState.settings : "";
        screen = focusedScreen;
        payload = null;
        resetCountdown(0);
        mode = m;
    }

    function close() {
        resetCountdown(0);
        payload = null;
        returnMode = "";
        mode = "";
    }

    // Esc: from the subviews back to the control center; from the rest, to the clock.
    function back() {
        if (returnMode !== "") {
            mode = returnMode;
            returnMode = "";
        } else if (IslandState.subviews.includes(mode))
            mode = IslandState.controlCenter;
        else
            close();
    }

    // OSD/notification: only appear when no surface opened by the user is showing.
    function showTransient(m, data, timeout) {
        if (IslandState.isSurface(mode))
            return false;
        screen = focusedScreen;
        payload = data;
        resetCountdown(timeout ?? OsdConfig.timeout);
        mode = m;
        return true;
    }

    function resetCountdown(duration) {
        transientDuration = duration;
        transientElapsed = 0;
        transientTimer.last = Date.now();
    }

    function togglePin() {
        pinned = !pinned;
    }

    // A single cheap tick (100 ms) while a transient is visible and not hovered. Measures the real
    // elapsed time (Date.now) so the timer's own delay does not accumulate.
    Timer {
        id: transientTimer

        property real last: 0

        interval: 100
        repeat: true
        running: root.transientDuration > 0 && !root.held && IslandState.isTransient(root.mode)
        onRunningChanged: last = Date.now()
        onTriggered: {
            const now = Date.now();
            root.transientElapsed += now - last;
            last = now;
            if (root.transientElapsed >= root.transientDuration)
                root.close();
        }
    }
}
