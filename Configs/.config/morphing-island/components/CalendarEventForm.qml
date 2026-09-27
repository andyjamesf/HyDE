import QtQuick
import qs.config
import qs.services
import qs.theme

// New Google Calendar event (calendar page "+"). Simple: title, date and an optional time
// (empty = all day), Enter saves. "More options": calendar, all day, start and end, repeat (days,
// weeks on chosen weekdays, months or years; from a date to a date, or n times), event colour,
// location, description and reminders. Not connected yet: the Google setup instead.
// Saving goes through GoogleCalendar.add (scripts/gcal.py); the event shows in the calendar at once.
Column {
    id: root

    // The day the form starts on (the calendar's chosen day).
    property date day: new Date()
    property bool full: false

    // Saved: the calendar goes back to the month.
    signal done

    spacing: 10

    // ——— helpers ———
    function pad(n) {
        return String(n).padStart(2, "0");
    }
    function isoDate(d) {
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    }
    function isoDateTime(d) {
        return `${isoDate(d)}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
    }
    function validDate(s) {
        return /^\d{4}-\d{2}-\d{2}$/.test(s) && !isNaN(new Date(s + "T00:00").getTime());
    }
    function validTime(s) {
        return /^\d{1,2}:\d{2}$/.test(s) && Number(s.split(":")[0]) < 24 && Number(s.split(":")[1]) < 60;
    }
    function timeOrEmpty(s) {
        return s === "" || validTime(s);
    }
    function normTime(s) {
        const [h, m] = s.split(":");
        return `${pad(h)}:${m}`;
    }

    // Fresh form for `d`.
    function reset(d) {
        day = d;
        full = false;
        title.text = "";
        startDate.text = isoDate(d);
        startTime.text = "";
        startDateSimple.text = isoDate(d);
        startTimeSimple.text = "";
        endDate.text = isoDate(d);
        endTime.text = "";
        allDay.value = false;
        repeat.value = "";
        weekdays.values = [];
        repeatUntil.text = "";
        repeatCount.text = "";
        colorPick.value = "";
        location.text = "";
        description.text = "";
        reminder.value = -1;
        message = "";
        calendar.value = GoogleCalendar.calendars.find(c => c.primary)?.id ?? "primary";
        GoogleCalendar.refreshStatus();
        title.focusField();
    }

    property string message: ""

    // The event for gcal.py, or a string saying what is wrong.
    function build() {
        const t = title.text.trim();
        if (t === "")
            return "Give the event a title";
        if (!validDate(startDate.text))
            return "The date must look like 2026-09-27";
        const whole = full ? allDay.value : startTime.text.trim() === "";
        const ev = {
            title: t,
            allDay: whole,
            calendar: calendar.value || "primary"
        };
        if (whole) {
            ev.start = startDate.text;
            ev.end = full && validDate(endDate.text) ? endDate.text : startDate.text;
        } else {
            if (!validTime(startTime.text.trim()))
                return "The time must look like 18:30";
            ev.start = `${startDate.text}T${normTime(startTime.text.trim())}`;
            if (full && endTime.text.trim() !== "") {
                if (!validDate(endDate.text) || !validTime(endTime.text.trim()))
                    return "The end must be a date and a time, like 2026-09-27 and 19:30";
                ev.end = `${endDate.text}T${normTime(endTime.text.trim())}`;
            } else {
                ev.end = isoDateTime(new Date(new Date(ev.start).getTime() + CalendarConfig.defaultDurationMinutes * 60000));
            }
        }
        if (full) {
            if (repeat.value !== "") {
                ev.repeat = {
                    freq: repeat.value
                };
                if (repeat.value === "WEEKLY" && weekdays.values.length > 0)
                    ev.repeat.days = weekdays.values;
                const until = repeatUntil.text.trim();
                const times = repeatCount.text.trim();
                if (until !== "") {
                    if (!validDate(until))
                        return "The repeat end must look like 2026-12-31";
                    if (until < startDate.text)
                        return "The repeat must end after it starts";
                    ev.repeat.until = until;
                } else if (times !== "") {
                    const n = parseInt(times);
                    if (!(n > 0))
                        return "How many times? Type a number";
                    ev.repeat.count = n;
                }
            }
            if (colorPick.value !== "")
                ev.color = colorPick.value;
            if (location.text.trim() !== "")
                ev.location = location.text.trim();
            if (description.text.trim() !== "")
                ev.description = description.text.trim();
            if (reminder.value === -2)
                ev.reminders = [];
            else if (reminder.value >= 0)
                ev.reminders = [reminder.value];
        }
        return ev;
    }

    function save() {
        const ev = build();
        if (typeof ev === "string") {
            message = ev;
            return;
        }
        message = "Saving…";
        GoogleCalendar.add(ev);
    }

    Connections {
        target: GoogleCalendar
        // The list may arrive after the form opened: select the primary calendar then.
        function onCalendarsChanged() {
            if (!GoogleCalendar.calendars.some(c => c.id === calendar.value))
                calendar.value = GoogleCalendar.calendars.find(c => c.primary)?.id ?? GoogleCalendar.calendars[0]?.id ?? "primary";
        }
        function onAdded(ok, text) {
            root.message = ok ? "" : text;
            if (ok)
                root.done();
        }
    }

    // ——— not connected: setup ———
    GoogleSetup {
        visible: !GoogleCalendar.connected
        width: parent.width
    }

    // ——— the form ———
    Column {
        visible: GoogleCalendar.connected
        width: parent.width
        spacing: 10

        Field {
            id: title
            width: parent.width
            placeholder: "Title"
            onAccepted: root.full ? startDate.focusField() : root.save()
        }

        // Simple: date and time on one row.
        Row {
            visible: !root.full
            spacing: 8
            Field {
                id: startDateSimple
                width: 150
                text: startDate.text
                placeholder: "2026-09-27"
                invalid: text !== "" && !root.validDate(text)
                onTextChanged: if (text !== startDate.text)
                    startDate.text = text
                onAccepted: root.save()
            }
            Field {
                id: startTimeSimple
                width: 120
                text: startTime.text
                placeholder: "Time (all day)"
                invalid: !root.timeOrEmpty(text.trim())
                onTextChanged: if (text !== startTime.text)
                    startTime.text = text
                onAccepted: root.save()
            }
        }

        // Full: every option.
        Column {
            visible: root.full
            width: parent.width
            spacing: 10

            Label {
                visible: GoogleCalendar.calendars.length > 0
                text: "Calendar"
                font.pixelSize: Appearance.fontSize - 2
                color: Theme.dim
            }
            Chips {
                id: calendar
                width: parent.width
                options: GoogleCalendar.calendars.map(c => ({
                            label: c.name,
                            value: c.id
                        }))
            }

            Chips {
                id: allDay
                value: false
                options: [
                    {
                        label: "At a time",
                        value: false
                    },
                    {
                        label: "All day",
                        value: true
                    }
                ]
            }

            Label {
                text: "Starts"
                font.pixelSize: Appearance.fontSize - 2
                color: Theme.dim
            }
            Row {
                spacing: 8
                Field {
                    id: startDate
                    width: 150
                    placeholder: "2026-09-27"
                    invalid: text !== "" && !root.validDate(text)
                    onTextChanged: if (repeatFrom.text !== text)
                        repeatFrom.text = text
                }
                Field {
                    id: startTime
                    visible: !allDay.value
                    width: 110
                    placeholder: "18:30"
                    invalid: !root.timeOrEmpty(text.trim())
                }
            }

            Label {
                text: allDay.value ? "Ends (last day)" : `Ends (empty: ${CalendarConfig.defaultDurationMinutes} min later)`
                font.pixelSize: Appearance.fontSize - 2
                color: Theme.dim
            }
            Row {
                spacing: 8
                Field {
                    id: endDate
                    width: 150
                    placeholder: "2026-09-27"
                    invalid: text !== "" && !root.validDate(text)
                }
                Field {
                    id: endTime
                    visible: !allDay.value
                    width: 110
                    placeholder: "19:30"
                    invalid: !root.timeOrEmpty(text.trim())
                }
            }

            Label {
                text: "Repeat"
                font.pixelSize: Appearance.fontSize - 2
                color: Theme.dim
            }
            Chips {
                id: repeat
                width: parent.width
                value: ""
                options: [
                    {
                        label: "Never",
                        value: ""
                    },
                    {
                        label: "Daily",
                        value: "DAILY"
                    },
                    {
                        label: "Weekly",
                        value: "WEEKLY"
                    },
                    {
                        label: "Monthly",
                        value: "MONTHLY"
                    },
                    {
                        label: "Yearly",
                        value: "YEARLY"
                    }
                ]
            }
            Chips {
                id: weekdays
                visible: repeat.value === "WEEKLY"
                width: parent.width
                multi: true
                options: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"].map((v, i) => ({
                            label: Clock.qtLocale.dayName((i + 1) % 7, Locale.ShortFormat),
                            value: v
                        }))
            }
            // Repeating: from which date to which date (an empty "to" = no end), or a number of times.
            // "From" is the event's first day (the same as "Starts").
            Column {
                visible: repeat.value !== ""
                width: parent.width
                spacing: 6

                Row {
                    spacing: 8
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "From"
                        font.pixelSize: Appearance.fontSize - 1
                        color: Theme.dim
                    }
                    Field {
                        id: repeatFrom
                        width: 130
                        placeholder: "2026-09-27"
                        invalid: text !== "" && !root.validDate(text)
                        onTextChanged: if (text !== startDate.text)
                            startDate.text = text
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "to"
                        font.pixelSize: Appearance.fontSize - 1
                        color: Theme.dim
                    }
                    Field {
                        id: repeatUntil
                        width: 130
                        placeholder: "no end"
                        invalid: text !== "" && !root.validDate(text)
                    }
                }

                Row {
                    spacing: 8
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "or"
                        font.pixelSize: Appearance.fontSize - 1
                        color: Theme.dim
                    }
                    Field {
                        id: repeatCount
                        width: 70
                        placeholder: "–"
                        invalid: text.trim() !== "" && !(parseInt(text) > 0)
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "times"
                        font.pixelSize: Appearance.fontSize - 1
                        color: Theme.dim
                    }
                }
            }

            Label {
                text: "Colour"
                font.pixelSize: Appearance.fontSize - 2
                color: Theme.dim
            }
            // Event colour: the calendar's own, or one of Google's eleven.
            Flow {
                id: colorPick
                property string value: ""
                width: parent.width
                spacing: 6

                Rectangle {
                    width: calLabel.implicitWidth + 20
                    height: 24
                    radius: 12
                    color: colorPick.value === "" ? Theme.accent : Theme.surface
                    border.width: colorPick.value === "" ? 0 : 1
                    border.color: Theme.border
                    Label {
                        id: calLabel
                        anchors.centerIn: parent
                        text: "Calendar's"
                        font.pixelSize: Appearance.fontSize - 2
                        color: colorPick.value === "" ? Theme.accentContent : Theme.foreground
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorPick.value = ""
                    }
                }

                Repeater {
                    model: GoogleCalendar.eventColors
                    Rectangle {
                        id: dot
                        required property var modelData
                        width: 24
                        height: 24
                        radius: 12
                        color: modelData.color
                        border.width: colorPick.value === modelData.id || dotMouse.containsMouse ? 2 : 0
                        border.color: Theme.foreground
                        MouseArea {
                            id: dotMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: colorPick.value = dot.modelData.id
                        }
                    }
                }
            }

            Field {
                id: location
                width: parent.width
                placeholder: "Location"
            }
            Field {
                id: description
                width: parent.width
                placeholder: "Description"
            }

            Label {
                text: "Reminder"
                font.pixelSize: Appearance.fontSize - 2
                color: Theme.dim
            }
            Chips {
                id: reminder
                width: parent.width
                value: -1
                options: [
                    {
                        label: "Calendar's",
                        value: -1
                    },
                    {
                        label: "None",
                        value: -2
                    }
                ].concat(CalendarConfig.reminderChoices.map(m => ({
                            label: m === 0 ? "At start" : m % 1440 === 0 ? `${m / 1440} day before` : m % 60 === 0 ? `${m / 60} h before` : `${m} min before`,
                            value: m
                        })))
            }
        }

        Row {
            spacing: 8
            CcTextButton {
                implicitHeight: 32
                text: root.full ? "Fewer options" : "More options"
                onClicked: {
                    root.full = !root.full;
                    if (root.full && endDate.text === "")
                        endDate.text = startDate.text;
                }
            }
            CcTextButton {
                implicitHeight: 32
                text: GoogleCalendar.busy ? "Saving…" : "Save"
                primary: true
                enabled: !GoogleCalendar.busy
                onClicked: root.save()
            }
        }

        Label {
            visible: root.message !== "" && root.message !== "Saving…"
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.message
            font.pixelSize: Appearance.fontSize - 2
            color: Theme.danger
        }
    }
}
