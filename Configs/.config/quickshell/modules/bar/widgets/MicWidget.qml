import QtQuick
import qs.components
import qs.services
import qs.modules.controls

// Microfone: só o ícone. Clique abre o painel de som; clique direito silencia; scroll ajusta.
BarItem {
    shown: !!Audio.source?.audio
    icon: Audio.micIcon
    iconFill: Audio.micMuted ? 0 : 1
    iconColor: Audio.micMuted ? Theme.textFaint : Theme.text
    tooltip: `${Audio.nameOf(Audio.source)}\n${Audio.micMuted ? "Microfone desligado" : Math.round(Audio.micVolume * 100) + "%"}`

    onRightClicked: Audio.toggleMicMute()
    popout: Component {
        AudioPanel {}
    }
    onScrolled: direction => Audio.setMicVolume(Audio.micVolume + direction * Config.widgets.audio.step / 100)
}
