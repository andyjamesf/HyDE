import QtQuick
import qs.config
import qs.services
import qs.theme

// Expanded mode (hover or pin): workspaces and media on the left, time and date in the middle,
// status on the right. Both side zones have the same width so the centre is truly centred.
// Sizes: config/Expanded.qml; workspaces: config/WorkspacesConfig.qml.
Item {
    id: root

    // The workspace indicator (the pill next to the clock slides in here when the island expands).
    readonly property bool showWorkspaces: WorkspacesConfig.enabled && WorkspacesConfig.inExpanded
    readonly property int workspacesWidth: showWorkspaces ? workspaces.implicitWidth + Expanded.gutter : 0
    // Width of each side zone: Expanded.sideMinWidth, or more if the natural content of either does
    // not fit (e.g. with a large pill height the media buttons get bigger).
    readonly property int side: Math.ceil(Math.max(Expanded.sideMinWidth, workspacesWidth + media.implicitWidth, status.implicitWidth))

    implicitWidth: 2 * side + center.implicitWidth + 2 * Expanded.gutter
    implicitHeight: Pill.height + Expanded.extraHeight

    // Left: workspaces, then media
    WorkspacesView {
        id: workspaces
        visible: root.showWorkspaces
        anchors.left: parent.left
        anchors.leftMargin: Expanded.margin
        anchors.verticalCenter: parent.verticalCenter
    }

    MediaZone {
        id: media
        anchors.left: parent.left
        anchors.leftMargin: Expanded.margin + root.workspacesWidth
        anchors.verticalCenter: parent.verticalCenter
        zoneWidth: root.side - root.workspacesWidth
    }

    Column {
        id: center
        anchors.centerIn: parent
        spacing: 0

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.time
            font.pixelSize: Appearance.fontSize + 3
            font.weight: Font.DemiBold
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.date
            font.pixelSize: Appearance.fontSize - 2
            color: Theme.dim
        }
    }

    // Right: status
    StatusZone {
        id: status
        anchors.right: parent.right
        anchors.rightMargin: Expanded.margin
        anchors.verticalCenter: parent.verticalCenter
        zoneWidth: root.side
    }
}
