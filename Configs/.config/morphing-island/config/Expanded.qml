pragma Singleton
import QtQuick
import Quickshell

// The expanded island (on hover or when pinned): media on the left, time and date in the middle,
// status icons on the right. Sizes scale from Pill.height.
Singleton {
    // Minimum width of each side zone in pixels (both sides get the same width so the clock stays
    // centred; they grow if their content needs more). Default 150.
    readonly property int sideMinWidth: 150
    // Space between each side zone and the centre, in pixels. Default 24.
    readonly property int gutter: 24
    // Distance from the island's left/right edges to the side zones, in pixels. Default 18.
    readonly property int margin: 18
    // Extra height over Pill.height, in pixels. Default 14.
    readonly property int extraHeight: 14

    // Status icons on the right, in this order. Known ids: "volume", "bluetooth", "wifi" (also shows
    // wired), "battery". Remove an id to hide that icon. Default ["volume", "bluetooth", "wifi",
    // "battery"].
    readonly property var statusIcons: ["volume", "bluetooth", "wifi", "battery"]
    // Space between status icons in pixels. Default 10.
    readonly property int statusSpacing: 10
    // Status icon size as a fraction of Pill.height. 0–1, default 0.45.
    readonly property real statusIconFactor: 0.45

    // Media zone: the album art is Pill.height minus this inset, in pixels. Default 6.
    readonly property int mediaArtInset: 6
    // Media buttons (previous / play / next) size as a fraction of Pill.height. 0–1, default 0.4.
    readonly property real mediaIconFactor: 0.4
    // Corner radius of the album art as a fraction of its size. 0–0.5, default 0.22.
    readonly property real mediaArtRadiusFactor: 0.22
}
