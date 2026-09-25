import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

// One window per screen: transparent, as big as the island's largest shape, but only the island
// receives clicks (mask). Reserves the space of the collapsed island at the top.
PanelWindow {
    id: win

    required property ShellScreen modelData
    // Pointer over the island (or faked by IPC).
    readonly property bool rawHover: island.hovered || IslandController.forceHover
    // Hover as seen by the base mode: on at once, off Pill.hoverCollapseDelay ms after leaving.
    property bool hoverHeld: false
    readonly property string displayMode: IslandController.modeFor(modelData.name, hoverHeld)
    readonly property bool surface: IslandState.isSurface(displayMode)
    // With the pointer over this screen's OSD/notification, the countdown pauses (and resumes on
    // leaving). Also re-evaluated when the transient moves to another screen, not only on hover.
    readonly property bool holding: rawHover && modelData.name === IslandController.screen
    onHoldingChanged: IslandController.held = holding

    onRawHoverChanged: {
        if (rawHover) {
            collapseTimer.stop();
            hoverHeld = true;
        } else {
            collapseTimer.restart();
        }
    }

    Timer {
        id: collapseTimer
        interval: Pill.hoverCollapseDelay
        onTriggered: win.hoverHeld = false
    }

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Math.min(modelData.height - 40, 760)
    // With the pill hidden only surfaces and transients show; the clock slides up off screen.
    readonly property bool baseHidden: Pill.hidden && (displayMode === IslandState.clock || displayMode === IslandState.expanded)

    exclusiveZone: Pill.hidden ? 0 : Pill.reservedHeight
    color: "transparent"
    mask: Region {
        item: win.baseHidden ? null : island
    }

    WlrLayershell.namespace: "quickshell:island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: IslandState.keyboardModes.includes(displayMode) ? WlrKeyboardFocus.Exclusive : surface ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Caffeine (control center tile): keeps the session from going idle while on.
    IdleInhibitor {
        window: win
        enabled: Caffeine.active
    }

    // Open surfaces: clicking outside closes them.
    // The grab only starts 60 ms after the surface opens: at the same time as the exclusive
    // keyboard focus, Hyprland cancelled it right away (the surface closed as soon as it opened).
    property bool grabReady: false
    // Re-armed on every mode change, also between two surfaces (e.g. media page → theme picker),
    // otherwise the new surface's grab starts too early and Hyprland cancels it.
    onDisplayModeChanged: grabReady = false

    Timer {
        running: win.surface && !win.grabReady
        interval: 60
        onTriggered: win.grabReady = true
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.surface && win.grabReady
        onCleared: IslandController.close()
    }

    // Hiding/showing the pill: it slides up off screen (and back) with the same spring.
    Spring {
        id: ySpring
        target: win.baseHidden ? -island.height - 16 : Pill.topMargin
    }

    Island {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: ySpring.value
        mode: win.displayMode
        focus: true
        Keys.onEscapePressed: IslandController.back()
        onEmptyClicked: {
            if (!IslandState.isSurface(mode) && !IslandState.isTransient(mode))
                IslandController.togglePin();
        }
    }
}
