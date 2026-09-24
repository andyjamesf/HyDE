import QtQuick

// Carrega um widget da barra pelo id usado no config.json.
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
    // O widget quer aparecer? (lido pela Island, que não pode usar `visible`: esse depende também
    // da própria Island, e uma ilha que começasse vazia nunca chegaria a aparecer.)
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
