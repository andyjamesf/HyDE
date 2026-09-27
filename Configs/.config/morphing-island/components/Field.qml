import QtQuick
import qs.config
import qs.theme

// One-line text field in the island's look: rounded, a placeholder, accent border with focus (red
// when `invalid`). Used by the calendar forms.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool invalid: false

    // Enter (either key).
    signal accepted

    function focusField() {
        input.forceActiveFocus();
    }

    implicitWidth: 200
    implicitHeight: 34
    radius: height / 2
    color: Theme.surface
    border.width: input.activeFocus || invalid ? 1.5 : 1
    border.color: invalid ? Theme.danger : input.activeFocus ? Theme.accent : Theme.border

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.foreground
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentContent
        font.family: Appearance.font
        font.pixelSize: Appearance.fontSize
        clip: true
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()

        Label {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            text: root.placeholder
            color: Theme.faint
        }
    }
}
