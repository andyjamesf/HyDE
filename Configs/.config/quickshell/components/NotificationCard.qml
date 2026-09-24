import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services

// Uma notificação: ícone/imagem, app, hora, título, corpo, ações e botão de fechar.
// Clicar no cartão executa a ação por omissão da app (se houver) e fecha-o.
Rectangle {
    id: root

    required property Notification notification
    property bool popup: false
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var actions: (notification?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property var defaultAction: (notification?.actions ?? []).find(a => a.identifier === "default") ?? null
    // O hover chega a todas as áreas sob o cursor, por isso esta cobre também os botões.
    readonly property bool hovered: area.containsMouse

    signal closed

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 24
    radius: BarLayout.hyprRounding + 8
    color: popup ? Theme.alpha(Theme.surfaceContainer, 0.97) : Theme.surfaceContainerHigh
    border.width: critical ? 2 : 1
    border.color: critical ? Theme.error : Theme.alpha(Theme.outlineVariant, 0.8)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && root.defaultAction)
                root.defaultAction.invoke();
            root.closed();
            if (mouse.button === Qt.MiddleButton || root.defaultAction)
                root.notification.dismiss();
        }
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 44
            implicitHeight: 44
            radius: 12
            color: Theme.surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                icon: root.critical ? "priority_high" : "notifications"
                size: 22
                fill: 1
                color: root.critical ? Theme.error : Theme.primary
            }

            Image {
                id: img
                anchors.fill: parent
                source: Notifs.imageOf(root.notification)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 88
                sourceSize.height: 88
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: root.notification?.appName || "Notificação"
                    font.pixelSize: 11
                    color: Theme.textDim
                }

                StyledText {
                    text: Utils.relativeTime(Notifs.timeOf(root.notification))
                    font.pixelSize: 10
                    color: Theme.textFaint
                }

                IconButton {
                    icon: "close"
                    size: 22
                    onClicked: {
                        root.closed();
                        root.notification.dismiss();
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.summary ?? ""
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: (root.notification?.body ?? "").replace(/<img[^>]*>/g, "")
                textFormat: Text.StyledText
                color: Theme.textDim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: root.popup ? 4 : 6
                elide: Text.ElideRight
                linkColor: Theme.primary
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.actions.length > 0
                spacing: 6

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: action

                        required property var modelData

                        implicitWidth: actionText.implicitWidth + 24
                        implicitHeight: 30
                        radius: 15
                        color: Theme.primaryContainer

                        StyledText {
                            id: actionText
                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.pixelSize: 12
                            color: Theme.onPrimaryContainer
                        }

                        StateLayer {
                            anchors.fill: parent
                            onClicked: {
                                action.modelData.invoke();
                                root.closed();
                                if (!root.notification.resident)
                                    root.notification.dismiss();
                            }
                        }
                    }
                }
            }
        }
    }
}
