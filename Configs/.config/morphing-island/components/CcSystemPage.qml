import QtQuick
import qs.config
import qs.core
import qs.icons
import qs.services
import qs.theme

// System page of the control center ("system" mode; the chip button in the header): CPU (total,
// each core, frequency, load), memory and swap, temperatures, GPU, storage, network and disk
// speed, power drawn from the battery and the busiest processes. Refreshed every 2 seconds while
// on screen (services/SysStats.qml).
Item {
    id: root

    property bool shown: false
    onShownChanged: SysStats.users += shown ? 1 : -1
    Component.onDestruction: if (shown)
        SysStats.users -= 1

    readonly property int pad: ControlCenter.padding
    readonly property var d: SysStats.data

    function pct(used, total) {
        return total > 0 ? used / total : 0;
    }
    function tempColor(c) {
        return c >= 85 ? Theme.danger : c >= 70 ? Theme.accent : Theme.foreground;
    }

    implicitWidth: ControlCenter.width
    implicitHeight: header.y + header.height + 6 + Math.min(body.implicitHeight, 620) + pad

    CcHeader {
        id: header
        x: root.pad
        y: 10
        width: root.width - 2 * root.pad
        title: "System"
    }

    Label {
        anchors.centerIn: parent
        visible: !root.d
        text: "Reading…"
        color: Theme.dim
    }

    Flickable {
        x: root.pad
        y: header.y + header.height + 6
        width: root.width - 2 * root.pad
        height: Math.min(body.implicitHeight, 620)
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: !!root.d

        Column {
            id: body
            width: parent.width
            spacing: 14

            // CPU: total, then one thin bar per core.
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Label {
                        width: parent.width - cpuPct.implicitWidth
                        text: "CPU"
                        font.weight: Font.DemiBold
                    }
                    Label {
                        id: cpuPct
                        text: `${Math.round(root.d?.cpu.percent ?? 0)}%`
                        font.weight: Font.DemiBold
                    }
                }
                Meter {
                    value: (root.d?.cpu.percent ?? 0) / 100
                }
                Row {
                    width: parent.width
                    spacing: 3
                    Repeater {
                        model: root.d?.cpu.cores ?? []
                        Rectangle {
                            required property var modelData
                            readonly property int n: root.d?.cpu.cores.length ?? 1
                            width: (parent.width - 3 * (n - 1)) / n
                            height: 22
                            radius: 3
                            color: Qt.alpha(Theme.foreground, 0.08)
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(2, parent.height * modelData / 100)
                                radius: 3
                                color: Theme.accent
                            }
                        }
                    }
                }
                Label {
                    width: parent.width
                    text: [root.d?.cpu.model ?? "", root.d ? `${(root.d.cpu.freq / 1000).toFixed(2)} GHz` : "", root.d ? `load ${root.d.cpu.load.map(x => x.toFixed(2)).join(" ")}` : ""].filter(x => x).join("  ·  ")
                    color: Theme.dim
                    font.pixelSize: Appearance.fontSize - 2
                }
            }

            // Memory and swap.
            Column {
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    Label {
                        width: parent.width - memText.implicitWidth
                        text: "Memory"
                        font.weight: Font.DemiBold
                    }
                    Label {
                        id: memText
                        text: root.d ? `${SysStats.bytes(root.d.memory.used)} / ${SysStats.bytes(root.d.memory.total)}` : ""
                        color: Theme.dim
                    }
                }
                Meter {
                    value: root.pct(root.d?.memory.used ?? 0, root.d?.memory.total ?? 0)
                }
                Label {
                    visible: (root.d?.memory.swapTotal ?? 0) > 0
                    text: root.d ? `Swap ${SysStats.bytes(root.d.memory.swapUsed)} / ${SysStats.bytes(root.d.memory.swapTotal)}` : ""
                    color: Theme.dim
                    font.pixelSize: Appearance.fontSize - 2
                }
            }

            // GPU.
            Column {
                visible: !!root.d?.gpu
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    Label {
                        width: parent.width - gpuText.implicitWidth
                        text: "GPU"
                        font.weight: Font.DemiBold
                    }
                    Label {
                        id: gpuText
                        text: root.d?.gpu ? `${root.d.gpu.percent}%` + (root.d.gpu.vramTotal > 0 ? `  ·  VRAM ${SysStats.bytes(root.d.gpu.vramUsed)} / ${SysStats.bytes(root.d.gpu.vramTotal)}` : "") : ""
                        color: Theme.dim
                    }
                }
                Meter {
                    value: (root.d?.gpu?.percent ?? 0) / 100
                }
            }

            // Temperatures: a chip per sensor.
            Column {
                visible: (root.d?.temps ?? []).length > 0
                width: parent.width
                spacing: 6
                Label {
                    text: "Temperatures"
                    font.weight: Font.DemiBold
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: root.d?.temps ?? []
                        Rectangle {
                            required property var modelData
                            width: tempRow.implicitWidth + 20
                            height: 30
                            radius: 15
                            color: Qt.alpha(Theme.foreground, 0.05)
                            border.width: 1
                            border.color: Theme.border
                            Row {
                                id: tempRow
                                anchors.centerIn: parent
                                spacing: 6
                                Label {
                                    text: modelData.name
                                    color: Theme.dim
                                    font.pixelSize: Appearance.fontSize - 1
                                }
                                Label {
                                    text: `${Math.round(modelData.celsius)}°C`
                                    color: root.tempColor(modelData.celsius)
                                    font.weight: Font.DemiBold
                                    font.pixelSize: Appearance.fontSize - 1
                                }
                            }
                        }
                    }
                }
            }

            // Storage.
            Column {
                visible: (root.d?.disks ?? []).length > 0
                width: parent.width
                spacing: 6
                Label {
                    text: "Storage"
                    font.weight: Font.DemiBold
                }
                Repeater {
                    model: root.d?.disks ?? []
                    Column {
                        required property var modelData
                        width: parent.width
                        spacing: 4
                        Row {
                            width: parent.width
                            Label {
                                width: parent.width - diskText.implicitWidth
                                text: modelData.mount
                                font.pixelSize: Appearance.fontSize - 1
                            }
                            Label {
                                id: diskText
                                text: `${SysStats.bytes(modelData.used)} / ${SysStats.bytes(modelData.total)}`
                                color: Theme.dim
                                font.pixelSize: Appearance.fontSize - 1
                            }
                        }
                        Meter {
                            value: root.pct(modelData.used, modelData.total)
                        }
                    }
                }
            }

            // Network, disk activity, power, uptime.
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: root.d ? [
                        {
                            k: "Download",
                            v: `${SysStats.bytes(root.d.net.rx)}/s`
                        },
                        {
                            k: "Upload",
                            v: `${SysStats.bytes(root.d.net.tx)}/s`
                        },
                        {
                            k: "Disk read",
                            v: `${SysStats.bytes(root.d.diskio.read)}/s`
                        },
                        {
                            k: "Disk write",
                            v: `${SysStats.bytes(root.d.diskio.write)}/s`
                        }
                    ].concat(root.d.power ? [
                            {
                                k: "Battery draw",
                                v: `${root.d.power} W`
                            }
                        ] : []).concat([
                        {
                            k: "Up",
                            v: SysInfo.uptime
                        }
                    ]) : []
                    Rectangle {
                        required property var modelData
                        width: (parent.width - 6) / 2
                        height: 44
                        radius: 14
                        color: Qt.alpha(Theme.foreground, 0.05)
                        border.width: 1
                        border.color: Theme.border
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                text: modelData.k
                                color: Theme.dim
                                font.pixelSize: Appearance.fontSize - 2
                            }
                            Label {
                                text: modelData.v
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            // Busiest processes.
            Column {
                visible: (root.d?.processes ?? []).length > 0
                width: parent.width
                spacing: 4
                Label {
                    text: "Top processes"
                    font.weight: Font.DemiBold
                }
                Repeater {
                    model: root.d?.processes ?? []
                    Row {
                        required property var modelData
                        width: parent.width
                        Label {
                            width: parent.width - 150
                            text: modelData.name
                            font.pixelSize: Appearance.fontSize - 1
                        }
                        Label {
                            width: 60
                            horizontalAlignment: Text.AlignRight
                            text: `${modelData.cpu.toFixed(1)}%`
                            font.pixelSize: Appearance.fontSize - 1
                        }
                        Label {
                            width: 90
                            horizontalAlignment: Text.AlignRight
                            text: SysStats.bytes(modelData.memory)
                            color: Theme.dim
                            font.pixelSize: Appearance.fontSize - 1
                        }
                    }
                }
            }
        }
    }

    // A thin rounded level bar.
    component Meter: Rectangle {
        property real value: 0
        width: parent ? parent.width : 0
        height: 8
        radius: 4
        color: Qt.alpha(Theme.foreground, 0.08)
        Rectangle {
            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, parent.value)))
            height: parent.height
            radius: 4
            color: parent.value > 0.9 ? Theme.danger : Theme.accent
            Behavior on width {
                NumberAnimation {
                    duration: Animations.duration(300)
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
