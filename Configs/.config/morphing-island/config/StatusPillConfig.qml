pragma Singleton
import QtQuick
import Quickshell

// Status pill: a small pill with the battery and other status at a glance (the mirror of the
// workspace pill on the left). With the clock pill showing it sits at the screen's right edge (or
// next to the clock); when the island expands it slides into it, whose right zone shows the status.
Singleton {
    // Show the status pill at all. Default true.
    readonly property bool enabled: true
    // Where it sits: "right" = the screen's right edge, "clock" = just right of the clock pill.
    // Default "right".
    readonly property string placement: "right"
    // Distance from the screen's right edge ("right" placement), in pixels. Default 12.
    readonly property int edgeMargin: 12
    // Space between the status pill and the clock pill ("clock" placement), in pixels. Default 8.
    readonly property int gap: 8
    // Inner padding at each end of the pill, in pixels. Default 12.
    readonly property int padding: 12

    // What it shows, in this order. Ids: "caffeine" (only while on), "notifications" (bell with the
    // unread count; only when there are some, or in peace mode), "volume", "bluetooth", "wifi" (also
    // wired), "battery" (hidden on PCs without one). Default
    // ["caffeine", "notifications", "volume", "bluetooth", "wifi", "battery"].
    readonly property var icons: ["caffeine", "notifications", "volume", "bluetooth", "wifi", "battery"]
    // Battery percentage, inside the battery icon. Default true.
    readonly property bool batteryPercent: true
    // Time left next to the battery: until empty on battery, until full while charging ("3h 12m";
    // hidden while UPower has no estimate yet, and when plugged in and full). Default true.
    readonly property bool batteryTime: true
}
