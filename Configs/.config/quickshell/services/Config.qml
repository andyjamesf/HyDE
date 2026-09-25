pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings, in config/config.json. The defaults live here:
// the file only needs what you want to change. Changes are applied live.
Singleton {
    id: root

    readonly property alias bar: adapter.bar
    readonly property alias appearance: adapter.appearance
    readonly property alias widgets: adapter.widgets


    FileView {
        path: Quickshell.shellPath("config/config.json")
        watchChanges: true
        onFileChanged: reload()
        // Invalid JSON must not bring the shell down: the last good values are kept.
        onLoadFailed: error => console.warn("config.json:", FileViewError.toString(error))

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject {
                // Default layout (one of the names in config/layouts.json).
                property string layout: "islands"
                // "top" | "bottom" (layouts can enforce their own position)
                property string position: "top"
                property real opacity: 0.92
                // Island background: "surface", "tint", "container", "accent", "glass", "outline"
                // or a fixed color ("#rrggbb"). Can be changed in the HyDE menu.
                property string pillStyle: "tint"
                // Layout to use automatically with each HyDE theme, e.g. { "Catppuccin-Mocha": "minimal" }.
                property var themeLayouts: ({})
            }

            property JsonObject appearance: JsonObject {
                // Language for dates (month and weekday names).
                property string locale: "en_GB"
                property string font: "Inter"
                property string monoFont: "JetBrainsMono Nerd Font"
                property string iconFont: "Material Symbols Rounded"
                property int fontSize: 12
                property int iconSize: 17
                property int radius: 14
                // Multiplier for animation durations (0 disables them).
                property real animationScale: 1
            }

            property JsonObject widgets: JsonObject {
                property JsonObject workspaces: JsonObject {
                    // Minimum number of workspaces shown, even when empty.
                    property int shown: 5
                    property bool appIcons: true
                    property int maxIcons: 3
                }
                property JsonObject activeWindow: JsonObject {
                    property int maxWidth: 200
                }
                property JsonObject clock: JsonObject {
                    property string format: "HH:mm"
                    property string dateFormat: "ddd, d MMM"
                    property bool showDate: false
                }
                property JsonObject media: JsonObject {
                    property int maxWidth: 200
                    property bool cava: true
                }
                property JsonObject stats: JsonObject {
                    property int interval: 2000
                    property bool cpu: true
                    property bool memory: true
                    property bool temperature: true
                    property bool network: false
                }
                property JsonObject battery: JsonObject {
                    property bool showPercent: true
                    property int lowLevel: 15
                }
                property JsonObject brightness: JsonObject {
                    property bool showPercent: false
                    property int step: 5
                }
                property JsonObject notifications: JsonObject {
                    // Maximum time a popup stays visible (ms); apps can ask for less.
                    property int timeout: 5000
                    property int maxPopups: 4
                    property int historySize: 100
                }
                property JsonObject lock: JsonObject {
                    // false: locking uses HyDE's hyprlock instead of the shell's lock screen.
                    property bool enabled: true
                }
                property JsonObject osd: JsonObject {
                    property bool enabled: true
                    property int timeout: 1500
                }
                property JsonObject audio: JsonObject {
                    property bool showPercent: true
                    property int step: 5
                }
            }
        }
    }
}
