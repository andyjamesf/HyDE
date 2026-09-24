import qs.components
import qs.services

// Menu com as opções da shell (layout da barra, origem das cores) e as ações do HyDE
// (tema, wallpaper, animações, workflows, luz noturna…).
BarItem {
    icon: "palette"
    iconColor: Theme.primary
    tooltip: `Opções do HyDE e da shell\nLayout: ${BarLayout.preset.label ?? BarLayout.current}`
    menuOnLeftClick: true
    menu: [
        {
            label: "󰕮  Layout da barra",
            items: BarLayout.names.map(name => ({
                        label: BarLayout.presets[name].label ?? name,
                        checked: name === BarLayout.current,
                        action: () => BarLayout.select(name)
                    }))
        },
        {
            label: "󰆧  Ilhas da barra",
            items: BarLayout.pillStyles.map(s => ({
                        label: s.label,
                        checked: s.id === BarLayout.pillStyle,
                        action: () => BarLayout.setPillStyle(s.id)
                    })).concat([
                {
                    sep: true
                }
            ], [1, 0.85, 0.7, 0.5].map(v => ({
                        label: `Opacidade ${Math.round(v * 100)}%`,
                        checked: Math.abs(BarLayout.opacity - v) < 0.01,
                        action: () => BarLayout.setPillOpacity(v)
                    })))
        },
        {
            label: "󰏘  Cores da shell",
            items: [
                {
                    label: "Tema do HyDE (cores da barra)",
                    checked: Theme.source === "hyde",
                    action: () => Theme.setColorSource("hyde")
                },
                {
                    label: "Paleta do tema (wallbash)",
                    checked: Theme.source === "wallbash",
                    action: () => Theme.setColorSource("wallbash")
                },
                {
                    label: "Cores do wallpaper",
                    checked: Theme.source === "wallpaper",
                    action: () => Theme.setColorSource("wallpaper")
                },
                {
                    sep: true
                },
                {
                    label: "Modo wallbash do HyDE (sistema)…",
                    cmd: "hyde-shell wallbashtoggle.sh -m"
                }
            ]
        },
        {
            sep: true
        }
    ].concat(HydeActions.hyde)
}
