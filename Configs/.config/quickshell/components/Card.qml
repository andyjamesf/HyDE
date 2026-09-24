import QtQuick
import qs.services

// Superfície arrumada em cartão, para agrupar conteúdo nos painéis.
Rectangle {
    default property alias content: inner.data
    property int padding: 14

    implicitWidth: inner.implicitWidth + 2 * padding
    implicitHeight: inner.implicitHeight + 2 * padding
    radius: BarLayout.hyprRounding + 8
    color: Theme.surfaceContainerHigh

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: parent.padding
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
