import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.core
import qs.icons
import qs.services
import qs.theme

// Main page of the control center: header (time, date, battery), quick-toggle tiles
// (ControlCenter.tiles), volume and brightness sliders, a media row and, at the bottom, the
// notification history. The height grows with the history (up to maxRows rows; then it scrolls).
Item {
    id: root

    // True while this is the page on screen with the control center open.
    property bool shown: false

    readonly property int pad: ControlCenter.padding
    readonly property int gap: ControlCenter.spacing
    readonly property int notifRowHeight: ControlCenter.notificationRowHeight
    readonly property int maxRows: ControlCenter.maxNotificationRows
    readonly property int notifCount: Notifications.count
    readonly property int visibleRows: Math.min(notifCount, maxRows)

    readonly property string outputName: (Audio.sinks ?? []).find(s => s.isDefault)?.name ?? ""

    implicitWidth: ControlCenter.width
    implicitHeight: column.implicitHeight + 2 * pad

    // Switches pages inside the control center, on the same screen.
    function go(p) {
        IslandController.mode = p;
    }

    // "now", "5m", "2h", "3d" (Time.now ticks every second, which is plenty for this).
    function ago(d) {
        const s = Math.max(0, (Time.now.getTime() - new Date(d).getTime()) / 1000);
        if (s < 60)
            return "now";
        if (s < 3600)
            return `${Math.floor(s / 60)}m`;
        if (s < 86400)
            return `${Math.floor(s / 3600)}h`;
        return `${Math.floor(s / 86400)}d`;
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: root.gap

        // Header: time and date on the left, battery on the right.
        Item {
            width: parent.width
            height: 30

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.time
                    font.pixelSize: Appearance.fontSize + 7
                    font.weight: Font.DemiBold
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.longDate
                    color: Theme.dim
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                visible: Battery.available

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.round(Battery.percent)}%`
                    color: Theme.dim
                    font.pixelSize: Appearance.fontSize - 1
                }

                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 20
                    showPercent: false
                    present: Battery.available
                    percent: Battery.percent
                    charging: Battery.charging
                }
            }
        }

        // Tiles: two columns, in the order of ControlCenter.tiles; an odd last tile takes the whole row.
        Flow {
            id: tiles
            width: parent.width
            spacing: 10

            readonly property real half: (width - spacing) / 2
            readonly property var ids: ControlCenter.tiles.filter(t => root.tileComponents[t] !== undefined)

            Repeater {
                model: tiles.ids

                Loader {
                    required property string modelData
                    required property int index

                    width: index === tiles.ids.length - 1 && index % 2 === 0 ? tiles.width : tiles.half
                    sourceComponent: root.tileComponents[modelData]
                }
            }
        }

        // Sliders
        Column {
            width: parent.width
            spacing: 10

            BigSlider {
                id: volumeSlider
                width: parent.width
                value: Audio.volume
                muted: Audio.muted
                label: Audio.muted ? "Muted" : `${Math.round(Audio.volume * 100)}%`
                iconClickable: true
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()

                VolumeIcon {
                    size: 16
                    color: volumeSlider.iconColor
                    level: Audio.volume
                    muted: Audio.muted
                }
            }

            BigSlider {
                id: brightnessSlider
                width: parent.width
                visible: Brightness.available
                value: Brightness.percent / 100
                label: `${Brightness.percent}%`
                // Every change is a process (brightnessctl): at most one per ControlCenter.sliderThrottleMs.
                throttle: ControlCenter.sliderThrottleMs
                onMoved: v => Brightness.set(v * 100)

                BrightnessIcon {
                    size: 16
                    color: brightnessSlider.iconColor
                    level: Brightness.percent / 100
                }
            }
        }

        // Media: compact row that opens the player subview.
        Rectangle {
            id: mediaRow
            width: parent.width
            height: 56
            visible: Media.active
            radius: 18
            color: mediaMouse.pressed ? Theme.pressed : mediaMouse.containsMouse ? Theme.hover : Qt.alpha(Theme.foreground, 0.04)
            border.width: 1
            border.color: Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: Animations.duration(120)
                }
            }

            MouseArea {
                id: mediaMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.go(IslandState.media)
            }

            // Cover with rounded corners (mask); without a cover, a tinted square.
            Item {
                id: art
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40

                readonly property bool hasCover: cover.status === Image.Ready

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Qt.alpha(Theme.accent, 0.22)
                    visible: !art.hasCover

                    MediaIcon {
                        anchors.centerIn: parent
                        kind: "play"
                        size: 16
                        color: Theme.accent
                    }
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: Media.artUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 80
                    sourceSize.height: 80
                    asynchronous: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: cover
                    visible: art.hasCover
                    maskEnabled: true
                    maskSource: artMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }

                Item {
                    id: artMask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "black"
                    }
                }
            }

            Column {
                anchors.left: art.right
                anchors.leftMargin: 12
                anchors.right: playButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Label {
                    width: parent.width
                    text: Media.title || Media.identity || "Unknown"
                    textFormat: Text.PlainText
                    font.weight: Font.Medium
                }

                Label {
                    width: parent.width
                    visible: text !== ""
                    text: Media.artist
                    textFormat: Text.PlainText
                    color: Theme.dim
                    font.pixelSize: Appearance.fontSize - 2
                }
            }

            IconButton {
                id: playButton
                anchors.right: mediaChevron.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                size: 34
                onClicked: Media.togglePlaying()

                MediaIcon {
                    kind: Media.playing ? "pause" : "play"
                    size: 16
                    color: Theme.icon
                }
            }

            Glyph {
                id: mediaChevron
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                kind: "chevron"
                size: 14
                color: mediaMouse.containsMouse ? Theme.foreground : Theme.faint
            }
        }

        // Notifications: header + "Clear All".
        Item {
            width: parent.width
            height: 26

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: root.notifCount > 0 ? `Notifications  ·  ${root.notifCount}` : "Notifications"
                color: Theme.dim
                font.pixelSize: Appearance.fontSize - 1
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: clearLabel.implicitWidth + 20
                height: 24
                radius: height / 2
                visible: root.notifCount > 0
                color: clearMouse.pressed ? Theme.pressed : clearMouse.containsMouse ? Theme.hover : "transparent"

                Label {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear All"
                    color: clearMouse.containsMouse ? Theme.foreground : Theme.dim
                    font.pixelSize: Appearance.fontSize - 1
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clear()
                }
            }
        }

        // No notifications
        Column {
            width: parent.width
            visible: root.notifCount === 0
            topPadding: 4
            bottomPadding: 8
            spacing: 2

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: Theme.faint
            }

            Label {
                width: parent.width
                visible: Notifications.peaceMode
                horizontalAlignment: Text.AlignHCenter
                text: "Peace Mode is on"
                color: Theme.faint
                font.pixelSize: Appearance.fontSize - 2
            }
        }

        ListView {
            id: notifList
            width: parent.width
            height: root.visibleRows * root.notifRowHeight
            visible: root.notifCount > 0
            clip: true
            interactive: root.notifCount > root.maxRows
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: Notifications.list
            }

            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: Animations.duration(140)
                }
            }
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Animations.duration(180)
                }
            }
            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: Animations.duration(180)
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    to: 1
                    duration: Animations.duration(120)
                }
            }

            delegate: Item {
                id: notifRow

                required property var modelData
                readonly property var n: modelData

                width: ListView.view.width
                height: root.notifRowHeight

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.dismiss(notifRow.n)
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    radius: 14
                    color: rowMouse.pressed ? Theme.pressed : rowMouse.containsMouse ? Theme.hover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Animations.duration(120)
                        }
                    }
                }

                // App icon (or its initial, if there is none).
                Item {
                    id: lead
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28

                    IconImage {
                        id: appIcon
                        anchors.fill: parent
                        source: Notifications.imageOf(notifRow.n)
                        visible: status === Image.Ready
                        asynchronous: true
                        mipmap: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: appIcon.status !== Image.Ready
                        radius: width / 2
                        color: Qt.alpha(Theme.accent, 0.18)

                        Label {
                            anchors.centerIn: parent
                            text: (notifRow.n?.appName || "?").charAt(0).toUpperCase()
                            color: Theme.accent
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Column {
                    anchors.left: lead.right
                    anchors.leftMargin: 10
                    anchors.right: trail.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Label {
                        width: parent.width
                        text: notifRow.n?.summary || notifRow.n?.appName || ""
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.fontSize - 1
                        font.weight: Font.Medium
                    }

                    Label {
                        width: parent.width
                        text: notifRow.n?.appName || "Notification"
                        textFormat: Text.PlainText
                        color: Theme.dim
                        font.pixelSize: Appearance.fontSize - 3
                    }
                }

                // Relative time; with the pointer over it, a "×" (clicking dismisses).
                Item {
                    id: trail
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(timeLabel.implicitWidth, 16)
                    height: 20

                    Label {
                        id: timeLabel
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !rowMouse.containsMouse
                        text: root.ago(Notifications.timeOf(notifRow.n))
                        color: Theme.faint
                        font.pixelSize: Appearance.fontSize - 2
                    }

                    Glyph {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: rowMouse.containsMouse
                        kind: "close"
                        size: 14
                        color: Theme.dim
                    }
                }
            }
        }
    }

    // Tile id → component (see ControlCenter.tiles).
    readonly property var tileComponents: ({
            wifi: wifiTileComponent,
            bluetooth: btTileComponent,
            sound: soundTileComponent,
            peace: peaceTileComponent,
            nightlight: nightTileComponent,
            caffeine: caffeineTileComponent
        })

    Component {
        id: wifiTileComponent

        CcTile {
            id: wifiTile
            width: parent?.width ?? 0
            title: "Wi‑Fi"
            status: !Network.wifiEnabled ? (Network.wired ? "Ethernet" : "Off") : Network.connected ? Network.name : "Not connected"
            active: Network.wifiEnabled
            expandable: true
            onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
            onOpened: root.go(IslandState.wifi)

            WifiIcon {
                size: 18
                color: wifiTile.iconColor
                level: Network.wired ? 4 : Network.level
                enabled: Network.wifiEnabled || Network.wired
                connected: Network.connected
            }
        }
    }

    Component {
        id: btTileComponent

        CcTile {
            id: btTile
            width: parent?.width ?? 0
            title: "Bluetooth"
            status: Bluetooth.summary
            active: Bluetooth.enabled
            enabled: Bluetooth.available
            expandable: true
            onToggled: Bluetooth.setEnabled(!Bluetooth.enabled)
            onOpened: root.go(IslandState.bluetooth)

            BluetoothIcon {
                size: 18
                color: btTile.iconColor
                enabled: Bluetooth.enabled
                connected: Bluetooth.connected
            }
        }
    }

    Component {
        id: soundTileComponent

        CcTile {
            id: audioTile
            width: parent?.width ?? 0
            title: "Sound"
            status: Audio.muted ? "Muted" : root.outputName || `${Math.round(Audio.volume * 100)}%`
            active: !Audio.muted
            expandable: true
            onToggled: Audio.toggleMute()
            onOpened: root.go(IslandState.audio)

            VolumeIcon {
                size: 18
                color: audioTile.iconColor
                level: Audio.volume
                muted: Audio.muted
            }
        }
    }

    Component {
        id: peaceTileComponent

        CcTile {
            id: peaceTile
            width: parent?.width ?? 0
            title: "Peace Mode"
            status: Notifications.peaceMode ? "On" : "Off"
            active: Notifications.peaceMode
            onToggled: Notifications.togglePeace()

            Glyph {
                kind: Notifications.peaceMode ? "bellOff" : "bell"
                size: 18
                color: peaceTile.iconColor
            }
        }
    }

    Component {
        id: nightTileComponent

        CcTile {
            id: nightTile
            width: parent?.width ?? 0
            title: "Night Light"
            status: !NightLight.available ? "Unavailable" : NightLight.active ? "On" : "Off"
            active: NightLight.active
            enabled: NightLight.available
            onToggled: NightLight.toggle()

            MoonIcon {
                size: 17
                color: nightTile.iconColor
            }
        }
    }

    // Caffeine: an idle inhibitor on the island window (no dimming, lock or suspend while on).
    Component {
        id: caffeineTileComponent

        CcTile {
            id: caffeineTile
            width: parent?.width ?? 0
            title: "Caffeine"
            status: Caffeine.active ? "Staying awake" : "Off"
            active: Caffeine.active
            onToggled: Caffeine.toggle()

            Glyph {
                kind: "coffee"
                size: 18
                color: caffeineTile.iconColor
            }
        }
    }
}
