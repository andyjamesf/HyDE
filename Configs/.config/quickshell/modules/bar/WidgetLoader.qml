import QtQuick

// Loads a bar widget by the id used in config.json.
Loader {
    id: root

    required property string name
    required property var bar

    readonly property var files: ({
            "hyde": "HydeMenu",
            "workspaces": "Workspaces",
            "activeWindow": "ActiveWindow",
            "clock": "Clock",
            "media": "Media",
            "cava": "Cava",
            "aiUsage": "AiUsage",
            "tray": "Tray",
            "audio": "Audio",
            "mic": "Mic",
            "brightness": "Brightness",
            "network": "Network",
            "bluetooth": "Bluetooth",
            "battery": "Battery",
            "stats": "Stats",
            "idle": "Idle",
            "nightLight": "NightLight",
            "notifications": "Notifications",
            "power": "Power",
            "controlCenter": "ControlCenter"
        })

    source: files[name] ? Qt.resolvedUrl(`widgets/${files[name]}Widget.qml`) : ""
    // Does the widget want to appear? (read by the Island, which can't use `visible`: that also depends
    // on the Island itself, and an island that started empty would never show up.)
    readonly property bool wanted: status === Loader.Ready && (item.shown ?? true)
    visible: wanted
    asynchronous: false

    onLoaded: {
        if ("bar" in item)
            item.bar = Qt.binding(() => root.bar);
        if ("ipcName" in item)
            item.ipcName = root.name;
    }

    Component.onCompleted: if (!files[name])
        console.warn(`config.json: unknown widget "${name}"`)
}
