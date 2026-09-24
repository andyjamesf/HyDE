import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.services
import qs.modules.controls

// Bateria. Clique abre o painel (carga, tempo restante, perfil de energia).
BarItem {
    readonly property var cfg: Config.widgets.battery

    shown: Battery.available
    icon: Battery.icon
    iconFill: 1
    iconColor: Battery.low ? Theme.error : Battery.plugged ? Theme.success : Theme.text
    text: cfg.showPercent ? `${Battery.percent}%` : ""
    textColor: Battery.low ? Theme.error : Theme.text
    tooltip: `${Battery.percent}% · ${Battery.charging ? "a carregar" : Battery.plugged ? "ligado à corrente" : "em bateria"}` + (Battery.secondsLeft > 0 ? `\n${Utils.formatDuration(Battery.secondsLeft)} ${Battery.charging ? "até carregar" : "restantes"}` : "") + `\nPerfil: ${Battery.profileName}`

    popoutName: "battery"
    popout: Component {
        BatteryPanel {}
    }
}
