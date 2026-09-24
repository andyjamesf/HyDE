pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Definições do utilizador, em config/config.json. Os valores por omissão estão aqui:
// o ficheiro só precisa de ter o que se quer mudar. As alterações aplicam-se a quente.
Singleton {
    id: root

    readonly property alias bar: adapter.bar
    readonly property alias appearance: adapter.appearance
    readonly property alias widgets: adapter.widgets


    FileView {
        path: Quickshell.shellPath("config/config.json")
        watchChanges: true
        onFileChanged: reload()
        // Um JSON inválido não deve deitar a shell abaixo: fica-se com os últimos valores bons.
        onLoadFailed: error => console.warn("config.json:", FileViewError.toString(error))

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject {
                // Layout por omissão (um dos nomes em config/layouts.json).
                property string layout: "islands"
                // "top" | "bottom" (os layouts podem impor a sua própria posição)
                property string position: "top"
                property real opacity: 0.92
                // Fundo das ilhas: "surface", "tint", "container", "accent", "glass", "outline"
                // ou uma cor fixa ("#rrggbb"). Pode ser mudado no menu do HyDE.
                property string pillStyle: "tint"
                // Layout a usar automaticamente com cada tema do HyDE, ex.: { "Catppuccin-Mocha": "minimal" }.
                property var themeLayouts: ({})
            }

            property JsonObject appearance: JsonObject {
                // Língua das datas (nomes dos meses e dias da semana).
                property string locale: "en_GB"
                property string font: "Inter"
                property string monoFont: "JetBrainsMono Nerd Font"
                property string iconFont: "Material Symbols Rounded"
                property int fontSize: 12
                property int iconSize: 17
                property int radius: 14
                // Multiplicador das durações das animações (0 desliga-as).
                property real animationScale: 1
            }

            property JsonObject widgets: JsonObject {
                property JsonObject workspaces: JsonObject {
                    // Número mínimo de workspaces mostrados, mesmo vazios.
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
                    // Tempo máximo que um popup fica visível (ms); as apps podem pedir menos.
                    property int timeout: 5000
                    property int maxPopups: 4
                    property int historySize: 100
                }
                property JsonObject lock: JsonObject {
                    // false: bloquear usa o hyprlock do HyDE em vez do lockscreen da shell.
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
