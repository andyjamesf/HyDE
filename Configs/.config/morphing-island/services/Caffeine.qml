pragma Singleton
import QtQuick
import Quickshell

// Caffeine: keeps the session awake (no dimming, locking or suspend by hypridle) while on. The
// inhibitor itself is an IdleInhibitor on each island window (core/IslandWindow.qml); this only
// holds the state, persisted as the Prefs key "idle.caffeine" so it survives reloads and restarts.
Singleton {
    readonly property bool active: Prefs.get("idle.caffeine", false)

    function toggle() {
        if (active)
            Prefs.reset("idle.caffeine");
        else
            Prefs.set("idle.caffeine", true);
    }
}
