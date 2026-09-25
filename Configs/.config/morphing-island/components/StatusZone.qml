import QtQuick
import qs.config
import qs.icons
import qs.services
import qs.theme

// Right zone of the expanded island: the icons listed in Expanded.statusIcons (volume, bluetooth,
// network, battery), right-aligned. Display only (no buttons): a click here falls through to the
// island background as empty space.
Item {
    id: root

    // Width assigned by ExpandedView (the content hugs the right edge inside it).
    property int zoneWidth: implicitWidth

    readonly property real iconSize: Math.round(Pill.height * Expanded.statusIconFactor)

    width: zoneWidth
    implicitWidth: row.implicitWidth
    implicitHeight: Pill.height

    // Icon id → component.
    readonly property var iconComponents: ({
            volume: volumeIcon,
            bluetooth: bluetoothIcon,
            wifi: wifiIcon,
            battery: batteryIcon
        })

    // Icons that only show when the hardware exists (a hidden icon takes no space in the row).
    function available(id) {
        return id === "bluetooth" ? Bluetooth.available : id === "battery" ? Battery.available : true;
    }

    Row {
        id: row
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Expanded.statusSpacing

        Repeater {
            model: Expanded.statusIcons.filter(i => root.iconComponents[i] !== undefined)

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

    Component {
        id: batteryIcon

        BatteryIcon {
            size: root.iconSize
            color: Theme.icon
            present: Battery.available
            percent: Battery.percent
            charging: Battery.charging
        }
    }
}
