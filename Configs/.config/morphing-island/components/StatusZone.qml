import QtQuick
import qs.config
import qs.icons
import qs.services
import qs.theme

// Status icons, right-aligned: the right zone of the expanded island (Expanded.statusIcons) and the
// status pill at the screen's right edge (StatusPillConfig.icons). Ids: "volume", "bluetooth",
// "wifi", "battery", "caffeine" (only while on), "notifications" (only with unread ones, or in
// peace mode). Display only (no buttons): a click here falls through to the island background.
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
            return Notifications.count > 0 || Notifications.peaceMode;
        return id === "bluetooth" ? Bluetooth.available : id === "battery" ? Battery.available : true;
    }

    Row {
        id: row
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Expanded.statusSpacing

        Repeater {
            model: root.icons.filter(i => root.iconComponents[i] !== undefined)

            Loader {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                visible: root.available(modelData)
                sourceComponent: root.iconComponents[modelData]
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
