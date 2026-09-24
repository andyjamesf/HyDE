import QtQuick
import qs.components
import qs.services
import qs.modules.controls

// Estado da rede. Clique abre a lista de redes; clique direito liga/desliga o Wi-Fi.
BarItem {
    icon: Network.icon
    iconFill: 1
    iconColor: Network.wifiEnabled || Network.wired ? Theme.text : Theme.textFaint
    tooltip: Network.wired ? "Ligado por cabo" : Network.activeWifi ? `${Network.name}\nSinal: ${Math.round(Network.signal * 100)}%` : Network.wifiEnabled ? "Wi-Fi sem ligação" : "Wi-Fi desligado"

    popoutName: "network"
    popout: Component {
        WifiPanel {}
    }
    onRightClicked: Network.setWifiEnabled(!Network.wifiEnabled)
}
