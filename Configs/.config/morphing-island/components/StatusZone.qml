import QtQuick
import qs.config
import qs.core
import qs.icons
import qs.services
import qs.theme

// Status icons, right-aligned: the right zone of the expanded island and the status pill at the
// screen's right edge (StatusPillConfig.icons). Ids: "volume", "bluetooth", "wifi", "battery",
// "caffeine" (only while on), "notifications" (bell with the unread count; crossed out in peace
// mode). Each icon is a button:
//   volume        click: audio page · middle click: mute · scroll: volume
//   bluetooth     click: Bluetooth page          wifi       click: network page
//   notifications click: notification center (the control center, with the history)
//   battery       click: control center          caffeine   click: turn caffeine off
Item {
    id: root

    // Width assigned by ExpandedView (the content hugs the right edge inside it).
    property int zoneWidth: implicitWidth
    // Icons to show, in order.
    property var icons: Expanded.statusIcons
    // Battery percentage, drawn inside the battery icon.
    property bool batteryPercent: true
    // Time left next to the battery icon: until empty on battery, until full while charging.
    property bool batteryTime: false
    // Keep the bell visible with no unread notifications (it opens the notification center).
    property bool alwaysShowBell: true

    // Click on an icon (see the list at the top).
    function activate(id, button) {
        if (id === "volume" && button === Qt.MiddleButton)
            Audio.toggleMute();
        else if (id === "volume")
            IslandController.open(IslandState.audio);
        else if (id === "bluetooth")
            IslandController.open(IslandState.bluetooth);
        else if (id === "wifi")
            IslandController.open(IslandState.wifi);
        else if (id === "caffeine")
            Caffeine.toggle();
        else
            IslandController.open(IslandState.controlCenter);
    }

    // "3h 12m" / "45m" from seconds; "" while UPower has no estimate.
    function duration(seconds) {
        const m = Math.round(seconds / 60);
        if (!(m > 0))
            return "";
        const h = Math.floor(m / 60);
        return h > 0 ? `${h}h ${String(m % 60).padStart(2, "0")}m` : `${m}m`;
    }
    readonly property string batteryText: batteryTime ? duration(Battery.charging ? Battery.timeToFull : Battery.plugged ? 0 : Battery.timeToEmpty) : ""

    readonly property real iconSize: Math.round(Pill.height * Expanded.statusIconFactor)
    // Padding around each icon button (its hover highlight), in pixels.
    readonly property int cellPadding: 3

    width: zoneWidth
    implicitWidth: row.implicitWidth
    implicitHeight: Pill.height

    // Icon id → component.
    readonly property var iconComponents: ({
            volume: volumeIcon,
            bluetooth: bluetoothIcon,
            wifi: wifiIcon,
            battery: batteryIcon,
            caffeine: caffeineIcon,
            notifications: notificationsIcon
        })

    // Icons that only show when they have something to say (a hidden icon takes no space in the row).
    function available(id) {
        if (id === "caffeine")
            return Caffeine.active;
        if (id === "notifications")
            return alwaysShowBell || Notifications.count > 0 || Notifications.peaceMode;
        return id === "bluetooth" ? Bluetooth.available : id === "battery" ? Battery.available : true;
    }

    Row {
        id: row
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        // Each button has its own padding (for the hover highlight), taken off the spacing.
        spacing: Math.max(0, Expanded.statusSpacing - 2 * root.cellPadding)

        Repeater {
            model: root.icons.filter(i => root.iconComponents[i] !== undefined)

            Item {
                id: cell

                required property string modelData

                anchors.verticalCenter: parent.verticalCenter
                visible: root.available(modelData)
                implicitWidth: icon.implicitWidth + 2 * root.cellPadding
                implicitHeight: Math.max(icon.implicitHeight, root.iconSize) + 2 * root.cellPadding

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"
                }

                Loader {
                    id: icon
                    anchors.centerIn: parent
                    sourceComponent: root.iconComponents[cell.modelData]
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: event => root.activate(cell.modelData, event.button)
                    onWheel: event => {
                        if (cell.modelData !== "volume")
                            return;
                        const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
                        Audio.setVolume(Math.max(0, Math.min(1, Audio.volume + step)));
                    }
                }
            }
        }
    }

    Component {
        id: volumeIcon

        VolumeIcon {
            size: root.iconSize
            color: Theme.icon
            level: Audio.volume
            muted: Audio.muted
        }
    }

    Component {
        id: bluetoothIcon

        BluetoothIcon {
            size: root.iconSize
            color: Bluetooth.enabled ? Theme.icon : Theme.dim
            enabled: Bluetooth.enabled
            connected: Bluetooth.connected
        }
    }

    // Wired: the wifi icon shows full and connected (no separate ethernet glyph).
    Component {
        id: wifiIcon

        WifiIcon {
            size: root.iconSize
            color: Network.wired || Network.connected ? Theme.icon : Theme.dim
            level: Network.wired ? 4 : Network.level
            enabled: Network.wired || Network.wifiEnabled
            connected: Network.wired || Network.connected
        }
    }

    // Battery (percentage inside it, if batteryPercent), then the time left (batteryTime; red when
    // low and not charging).
    Component {
        id: batteryIcon

        Row {
            spacing: 4

            BatteryIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: root.iconSize
                color: Theme.icon
                present: Battery.available
                percent: Battery.percent
                charging: Battery.charging
                showPercent: root.batteryPercent
            }

            Label {
                visible: root.batteryText !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryText
                font.pixelSize: Appearance.fontSize - 1
                color: Battery.percent <= 15 && !Battery.charging ? Theme.danger : Theme.foreground
            }
        }
    }

    // Caffeine on: the session never goes idle (control center tile or `island ipc caffeine`).
    Component {
        id: caffeineIcon

        Glyph {
            kind: "coffee"
            size: root.iconSize
            color: Theme.accent
        }
    }

    // Unread notifications (bell + count), or peace mode (crossed-out bell).
    Component {
        id: notificationsIcon

        Row {
            spacing: 3

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                kind: Notifications.peaceMode ? "bellOff" : "bell"
                size: root.iconSize
                color: Theme.icon
            }

            Label {
                visible: Notifications.count > 0
                anchors.verticalCenter: parent.verticalCenter
                text: String(Notifications.count)
                font.pixelSize: Appearance.fontSize - 1
            }
        }
    }
}
