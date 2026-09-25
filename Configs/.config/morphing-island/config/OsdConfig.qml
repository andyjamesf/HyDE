pragma Singleton
import QtQuick
import Quickshell

// On-screen displays (volume, microphone, brightness) shown in the island when a value changes.
// (Named OsdConfig because components/Osd.qml is the OSD view.)
Singleton {
    // How long an OSD stays visible after the last change (the countdown pauses while hovered).
    // Milliseconds, 500–10000, default 1500.
    readonly property int timeout: 1500
    // Width of the OSD in pixels. Default 300.
    readonly property int width: 300
    // Extra height over Pill.height, in pixels. Default 8.
    readonly property int extraHeight: 8
    // Thickness of the level bar in pixels. Default 6.
    readonly property int barThickness: 6
    // Show an OSD for microphone changes (mute toggle, input volume). Default true.
    readonly property bool showMic: true

    // Audio: Pipewire reports its initial values bit by bit after startup (or a device switch);
    // changes during this delay do not show the OSD. Milliseconds, default 1500.
    readonly property int audioArmDelay: 1500
    // Brightness: hypridle dims the screen to ~1% when idle and restores it on return. Changes from
    // or to at most this percentage never show the OSD. Percent, 0–10, default 2.
    readonly property int dimmingThreshold: 2
    // Step of Brightness.up()/down() in percent. Default 5.
    readonly property int brightnessStep: 5
}
