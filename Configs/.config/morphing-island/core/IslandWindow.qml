import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components
import qs.theme

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

        Region {
            item: win.satelliteShown ? satellite : null
        }
        Region {
            item: win.statusShown ? statusPill : null
        }
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

    // Workspace indicator pill (config/WorkspacesConfig.qml): at the screen's left edge or next to the
    // clock pill (WorkspacesConfig.placement). When the island leaves the clock (expands on hover or
    // pin, or shows anything else) it slides under the island and fades, as if absorbed; the
    // expanded island shows the workspaces itself.
    readonly property bool satelliteShown: WorkspacesConfig.enabled && displayMode === IslandState.clock && !baseHidden

    Spring {
        id: satX
        target: !win.satelliteShown ? island.x + (island.width - satellite.width) / 2 : WorkspacesConfig.placement === "clock" ? island.x - WorkspacesConfig.gap - satellite.width : WorkspacesConfig.edgeMargin
    }

    IslandSurface {
        id: satellite
        // Under the island, so it disappears behind it when absorbed.
        z: -1
        x: Math.round(satX.value)
        y: ySpring.value
        targetWidth: workspaces.implicitWidth + 2 * WorkspacesConfig.padding
        targetHeight: Pill.height
        opacity: win.satelliteShown ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Animations.duration(win.satelliteShown ? Animations.fadeIn : Animations.fadeOut)
                easing.type: Easing.OutCubic
            }
        }

        WorkspacesView {
            id: workspaces
            anchors.centerIn: parent
        }
    }

    // Status pill (config/StatusPillConfig.qml): battery (percentage and time left) and other status,
    // at the screen's right edge or next to the clock. Absorbed into the island like the workspace
    // pill; the expanded island shows the status in its right zone.
    readonly property bool statusShown: StatusPillConfig.enabled && displayMode === IslandState.clock && !baseHidden

    Spring {
        id: statusX
        target: !win.statusShown ? island.x + (island.width - statusPill.width) / 2 : StatusPillConfig.placement === "clock" ? island.x + island.width + StatusPillConfig.gap : win.width - StatusPillConfig.edgeMargin - statusPill.width
    }

    IslandSurface {
        id: statusPill
        z: -1
        x: Math.round(statusX.value)
        y: ySpring.value
        targetWidth: status.implicitWidth + 2 * StatusPillConfig.padding
        targetHeight: Pill.height
        opacity: win.statusShown ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Animations.duration(win.statusShown ? Animations.fadeIn : Animations.fadeOut)
                easing.type: Easing.OutCubic
            }
        }

        StatusZone {
            id: status
            anchors.centerIn: parent
            icons: StatusPillConfig.icons
            batteryPercent: StatusPillConfig.batteryPercent
            batteryTime: StatusPillConfig.batteryTime
            alwaysShowBell: StatusPillConfig.alwaysShowBell
        }
    }

    // Hint under a hovered status icon or shortcut button (IslandController.hint; text from
    // Shortcuts.hint), after the pointer rests a moment. Once one shows, moving to a neighbour
    // switches at once (hintArmed stays on while the pointer is off the icons less than 300 ms).
    property bool hintArmed: false

    Timer {
        id: hintDelay
        interval: 450
        onTriggered: win.hintArmed = true
    }
    Timer {
        id: hintGrace
        interval: 300
        onTriggered: win.hintArmed = false
    }
    Connections {
        target: IslandController
        function onHintPinnedChanged() {
            if (IslandController.hintPinned && IslandController.hintScreen === win.modelData.name) {
                hintDelay.stop();
                hintGrace.stop();
                win.hintArmed = true;
            }
        }
        function onHintChanged() {
            if (IslandController.hint !== "" && IslandController.hintScreen === win.modelData.name) {
                hintGrace.stop();
                if (IslandController.hintPinned)
                    win.hintArmed = true;
                else if (!win.hintArmed)
                    hintDelay.restart();
            } else {
                hintDelay.stop();
                hintGrace.restart();
            }
        }
    }

    Rectangle {
        id: hintPill
        readonly property bool showing: IslandController.hint !== "" && IslandController.hintScreen === win.modelData.name && win.hintArmed
        z: 10
        x: Math.round(Math.max(8, Math.min(win.width - width - 8, IslandController.hintAt.x - width / 2)))
        y: Math.round(IslandController.hintAt.y + 8)
        width: hintText.implicitWidth + 20
        height: hintText.implicitHeight + 10
        radius: Math.min(height / 2, 14)
        color: Qt.alpha(Theme.background, 0.96)
        border.width: 1
        border.color: Theme.border
        opacity: showing ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Animations.duration(120)
            }
        }

        Label {
            id: hintText
            anchors.centerIn: parent
            text: Shortcuts.hint(IslandController.hint)
            font.pixelSize: Appearance.fontSize - 1
        }
    }

    Island {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: ySpring.value
        mode: win.displayMode
        focus: true
        Keys.onEscapePressed: IslandController.back()
        // Clock pill: left click opens the calendar, right click the expanded island. Expanded:
        // any click on empty space closes it (a click on its time opens the calendar).
        onEmptyClicked: button => {
            if (IslandState.isSurface(mode) || IslandState.isTransient(mode))
                return;
            if (mode === IslandState.clock && button === Qt.LeftButton)
                IslandController.open(IslandState.calendar);
            else
                IslandController.togglePin();
        }
    }
}
