import QtQuick
import qs.config
import qs.core
import qs.icons
import qs.services
import qs.theme

// Calendar (island mode "calendar"): the month, the chosen day's events and your calendars.
// A click on a day shows its events; ‹ › change month, the month name goes back to today.
// Add a calendar: type or paste an iCal/webcal link and press Enter, "Paste link" (straight from
// the clipboard) or "Add .ics file…". Click a calendar's colour dot to pick another colour.
// Keyboard: ←/→ previous/next day, ↑/↓ a week, PageUp/PageDown a month, Esc closes.
// Data: services/Calendar.qml; options: config/CalendarConfig.qml.
Item {
    id: root

    property bool open: false
    readonly property real islandRadius: 26
    readonly property int pad: 16
    readonly property var locale: Clock.qtLocale

    // The day whose events are listed, and the month shown.
    property date selected: new Date()
    property int year: selected.getFullYear()
    property int month: selected.getMonth()
    // Feedback under "Add a calendar" (red when something went wrong).
    property string message: ""
    property bool messageError: false
    // Calendar whose colour palette is open (-1: none).
    property int colorFor: -1

    readonly property var days: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - (CalendarConfig.firstDayOfWeek % 7) + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; ++i)
            out.push(new Date(year, month, 1 - offset + i));
        return out;
    }
    readonly property var dayEvents: Calendar.eventsOn(selected).slice(0, CalendarConfig.maxEvents)

    focus: true
    implicitWidth: CalendarConfig.width
    implicitHeight: column.implicitHeight + 2 * pad

    onOpenChanged: if (open)
        reset()
    Component.onCompleted: if (open)
        reset()

    function reset() {
        select(new Date());
        message = "";
        colorFor = -1;
        input.text = "";
        Calendar.refresh(false);
        focusRetry.start();
    }

    function select(d) {
        selected = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        year = selected.getFullYear();
        month = selected.getMonth();
    }

    function stepMonth(delta) {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    // Adds the pasted link; on success the field empties, otherwise the reason shows below it.
    function addFromInput() {
        const why = Calendar.addLink(input.text);
        if (why === "")
            input.text = "";
        else {
            message = why;
            messageError = true;
        }
    }

    Connections {
        target: Calendar
        function onNotice(text, error) {
            root.message = text;
            root.messageError = error;
        }
    }

    function timeOf(e) {
        return e.allDay ? "All day" : root.locale.toString(e.start, Clock.timeFormat);
    }

    FocusRetry {
        id: focusRetry
        target: root
        when: root.open
    }

    Keys.onPressed: event => {
        const k = event.key;
        const shift = k === Qt.Key_Left ? -1 : k === Qt.Key_Right ? 1 : k === Qt.Key_Up ? -7 : k === Qt.Key_Down ? 7 : 0;
        if (shift !== 0) {
            select(new Date(selected.getFullYear(), selected.getMonth(), selected.getDate() + shift));
            event.accepted = true;
        } else if (k === Qt.Key_PageUp || k === Qt.Key_PageDown) {
            select(new Date(selected.getFullYear(), selected.getMonth() + (k === Qt.Key_PageUp ? -1 : 1), 1));
            event.accepted = true;
        }
    }

    // Under everything: swallows clicks on empty space (they must not toggle the island's pin).
    MouseArea {
        anchors.fill: parent
        onPressed: root.forceActiveFocus()
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: 12

        // Month header: ‹ September 2026 ›
        Item {
            width: parent.width
            height: 32

            IconButton {
                id: prevButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                onClicked: root.stepMonth(-1)
                Glyph {
                    kind: "back"
                    size: 16
                }
            }

            Label {
                anchors.centerIn: parent
                text: root.locale.toString(new Date(root.year, root.month, 1), "MMMM yyyy")
                font.pixelSize: Appearance.fontSize + 3
                font.weight: Font.DemiBold

                // The month name goes back to today.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.select(new Date())
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                onClicked: root.stepMonth(1)
                Glyph {
                    kind: "chevron"
                    size: 16
                }
            }
        }

        // Weekday names and the 6×7 day grid.
        Grid {
            id: grid
            width: parent.width
            columns: 7
            readonly property real cell: width / 7

            Repeater {
                model: 7
                Label {
                    required property int index
                    width: grid.cell
                    height: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: root.locale.dayName((CalendarConfig.firstDayOfWeek + index) % 7, Locale.NarrowFormat)
                    font.pixelSize: Appearance.fontSize - 2
                    color: Theme.dim
                }
            }

            Repeater {
                model: root.days

                Item {
                    id: day

                    required property var modelData
                    readonly property bool inMonth: modelData.getMonth() === root.month
                    // Time.date changes at midnight: the binding re-evaluates then.
                    readonly property bool today: Time.date !== "" && Calendar.sameDay(modelData, new Date())
                    readonly property bool chosen: Calendar.sameDay(modelData, root.selected)
                    // Up to three dots, in the colours of that day's calendars.
                    readonly property var dots: {
                        const seen = [];
                        for (const e of Calendar.eventsOn(modelData)) {
                            if (!seen.includes(e.color))
                                seen.push(e.color);
                            if (seen.length === 3)
                                break;
                        }
                        return seen;
                    }

                    width: grid.cell
                    height: 38

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 3
                        width: 30
                        height: 30
                        radius: 15
                        color: day.today ? Theme.accent : dayMouse.containsMouse ? Theme.hover : "transparent"
                        border.width: day.chosen && !day.today ? 1.5 : 0
                        border.color: Theme.accent

                        Label {
                            anchors.centerIn: parent
                            text: day.modelData.getDate()
                            font.weight: day.today || day.chosen ? Font.DemiBold : Font.Normal
                            color: day.today ? Theme.accentContent : day.inMonth ? Theme.foreground : Theme.faint
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        spacing: 3
                        Repeater {
                            model: day.dots
                            Rectangle {
                                required property var modelData
                                width: 4
                                height: 4
                                radius: 2
                                color: modelData || Theme.accent
                            }
                        }
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(day.modelData)
                    }
                }
            }
        }

        // The chosen day's events.
        Column {
            width: parent.width
            spacing: 6

            Label {
                text: Calendar.sameDay(root.selected, new Date()) ? "Today" : root.locale.toString(root.selected, Clock.longDateFormat)
                font.pixelSize: Appearance.fontSize - 1
                font.weight: Font.DemiBold
                color: Theme.dim
            }

            Label {
                visible: root.dayEvents.length === 0
                text: Calendar.calendars.length === 0 ? "No calendars yet: add one below" : Calendar.loading && Calendar.events.length === 0 ? "Loading…" : "No events"
                color: Theme.faint
            }

            Repeater {
                model: root.dayEvents

                Row {
                    id: ev
                    required property var modelData
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 28
                        radius: 2
                        color: ev.modelData.color || Theme.accent
                    }

                    Column {
                        width: parent.width - 14
                        Label {
                            width: parent.width
                            text: ev.modelData.title
                            font.weight: Font.Medium
                        }
                        Label {
                            width: parent.width
                            text: [root.timeOf(ev.modelData), ev.modelData.location, ev.modelData.calendar].filter(x => x).join("  ·  ")
                            font.pixelSize: Appearance.fontSize - 2
                            color: Theme.dim
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        // Your calendars: colour (click the dot to change it), name, remove.
        Column {
            width: parent.width
            spacing: 4

            Label {
                text: "Calendars"
                font.pixelSize: Appearance.fontSize - 1
                font.weight: Font.DemiBold
                color: Theme.dim
            }

            Repeater {
                model: Calendar.calendars

                Column {
                    id: cal
                    required property var modelData
                    required property int index
                    readonly property string error: Calendar.errors.find(x => x.startsWith(modelData.name + ":")) ?? ""
                    readonly property bool picking: root.colorFor === index
                    width: parent.width
                    spacing: 4

                    Item {
                        width: parent.width
                        height: 30

                        // The calendar's colour: a click opens the palette below.
                        Rectangle {
                            id: swatch
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: 8
                            color: cal.modelData.color || Theme.accent
                            border.width: swatchMouse.containsMouse || cal.picking ? 2 : 0
                            border.color: Theme.foreground

                            MouseArea {
                                id: swatchMouse
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.colorFor = cal.picking ? -1 : cal.index
                            }
                        }

                        Label {
                            anchors.left: swatch.right
                            anchors.leftMargin: 10
                            anchors.right: removeButton.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: cal.error !== "" ? `${cal.modelData.name}  ·  couldn't read it` : `${cal.modelData.name}  ·  ${cal.modelData.path ? "file" : "link"}`
                            color: cal.error !== "" ? Theme.danger : Theme.foreground
                        }

                        IconButton {
                            id: removeButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            size: 26
                            onClicked: {
                                root.colorFor = -1;
                                Calendar.remove(cal.index);
                            }
                            Glyph {
                                kind: "close"
                                size: 14
                            }
                        }
                    }

                    // Palette (CalendarConfig.colors).
                    Flow {
                        visible: cal.picking
                        width: parent.width
                        leftPadding: 26
                        spacing: 8
                        bottomPadding: 4

                        Repeater {
                            model: CalendarConfig.colors

                            Rectangle {
                                id: option
                                required property string modelData
                                readonly property bool chosen: modelData.toLowerCase() === String(cal.modelData.color).toLowerCase()
                                width: 22
                                height: 22
                                radius: 11
                                color: modelData
                                border.width: chosen || optionMouse.containsMouse ? 2 : 0
                                border.color: Theme.foreground

                                MouseArea {
                                    id: optionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Calendar.setColor(cal.index, option.modelData);
                                        root.colorFor = -1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Adding a calendar: an iCal link (typed, pasted into the field, or straight from the
        // clipboard with "Paste link") or a .ics file.
        Column {
            width: parent.width
            spacing: 8

            Label {
                text: "Add a calendar"
                font.pixelSize: Appearance.fontSize - 1
                font.weight: Font.DemiBold
                color: Theme.dim
            }

            Rectangle {
                width: parent.width
                height: 36
                radius: 18
                color: Theme.surface
                border.width: input.activeFocus ? 1.5 : 1
                border.color: input.activeFocus ? Theme.accent : Theme.border

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.foreground
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentContent
                    font.family: Appearance.font
                    font.pixelSize: Appearance.fontSize
                    clip: true
                    Keys.onReturnPressed: root.addFromInput()
                    Keys.onEnterPressed: root.addFromInput()

                    Label {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "iCal link (https:// or webcal://), Enter adds it"
                        color: Theme.faint
                    }
                }
            }

            Row {
                spacing: 8

                Repeater {
                    model: [
                        {
                            label: "Paste link",
                            run: () => Calendar.addFromClipboard()
                        },
                        {
                            label: "Add .ics file…",
                            run: () => Calendar.addFile()
                        }
                    ]

                    Rectangle {
                        id: button
                        required property var modelData
                        width: buttonLabel.implicitWidth + 28
                        height: 32
                        radius: 16
                        color: buttonMouse.pressed ? Theme.pressed : buttonMouse.containsMouse ? Theme.hover : Theme.surface
                        border.width: 1
                        border.color: Theme.border

                        Label {
                            id: buttonLabel
                            anchors.centerIn: parent
                            text: button.modelData.label
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.message = "";
                                button.modelData.run();
                            }
                        }
                    }
                }
            }

            Label {
                visible: root.message !== ""
                width: parent.width
                text: root.message
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.fontSize - 2
                color: root.messageError ? Theme.danger : Theme.dim
            }
        }
    }
}
