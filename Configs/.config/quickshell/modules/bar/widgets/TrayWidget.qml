import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.services

// Tray: clique ativa, clique direito abre o menu da app, meio faz a ação secundária.
// Os itens "passivos" ficam escondidos, como na Waybar. Os ícones monocromáticos (rede,
// Bluetooth, discos…) são pintados com a cor do texto, para se verem em qualquer tema.
Row {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    property bool shown: items.length > 0

    spacing: 2
    leftPadding: 4
    rightPadding: 4

    Repeater {
        model: root.items

        StateLayer {
            id: item

            required property SystemTrayItem modelData
            // Nome do ícone no tema (as apps mandam "image://icon/<nome>" ou uma imagem própria).
            readonly property string iconName: (/^image:\/\/icon\/([^?]+)/.exec(modelData.icon) ?? [])[1] ?? ""
            // Apps cujo ícone de estado é colorido, mas que têm equivalente simbólico genérico.
            readonly property var symbolicAliases: ({
                    "blueman-active": "bluetooth-active-symbolic",
                    "blueman-disabled": "bluetooth-disabled-symbolic",
                    "blueman-tray": "bluetooth-symbolic",
                    "blueman": "bluetooth-symbolic"
                })
            // Versão simbólica explícita (não se pode perguntar ao tema por "<nome>-symbolic": o Qt
            // encurta nomes que não existem e devolveria o ícone colorido).
            readonly property string symbolicName: {
                const alias = symbolicAliases[iconName] ?? "";
                return alias !== "" && Quickshell.hasThemeIcon(alias) ? alias : "";
            }
            readonly property bool hasSymbolic: symbolicName !== ""
            readonly property string source: hasSymbolic ? Quickshell.iconPath(symbolicName) : modelData.icon
            // Monocromáticos (simbólicos, …-panel, rede do nm-applet, discos) são pintados com a cor
            // do texto; os coloridos ficam com as cores originais.
            readonly property bool mono: hasSymbolic || /symbolic|-panel|indicator|icon\/nm-|drive-removable|audio-volume|battery-/i.test(modelData.icon)

            width: Math.round(BarLayout.height * 0.9)
            height: Math.round(root.height * 0.72)
            anchors.verticalCenter: parent.verticalCenter

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (mouse.button === Qt.RightButton || modelData.onlyMenu)
                    modelData.hasMenu && menuAnchor.open();
                else
                    modelData.activate();
            }
            onScrolled: direction => modelData.scroll(direction * 120, false)

            IconImage {
                id: trayIcon
                anchors.centerIn: parent
                // Os símbolos genéricos (ex.: Bluetooth) ocupam o quadrado todo, sem a margem que os
                // ícones de painel têm; reduzem-se para ficarem do tamanho dos restantes.
                implicitSize: Math.round((BarLayout.iconSize - 1) * (item.hasSymbolic ? 0.78 : 1))
                source: item.source
                visible: !item.mono
            }

            // Ícones monocromáticos pintados com a cor do texto. A colorização do MultiEffect
            // multiplica pela luminosidade do ícone, por isso primeiro leva-se o ícone ao extremo
            // certo: branco para cores claras, preto para cores escuras (temas claros).
            MultiEffect {
                readonly property color target: BarLayout.readable(Theme.text, 3)
                visible: item.mono
                anchors.fill: trayIcon
                source: trayIcon
                brightness: Theme.luminance(target) > 0.5 ? 1 : -1
                colorization: 1
                colorizationColor: target
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: item.modelData.menu
                anchor.item: item
                anchor.edges: BarLayout.atTop ? Edges.Bottom : Edges.Top
                anchor.gravity: BarLayout.atTop ? Edges.Bottom : Edges.Top
            }
        }
    }
}
