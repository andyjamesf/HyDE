import QtQuick
import qs.components
import qs.services
import qs.modules.controls

// Media (MPRIS): título e artista, com o visualizador cava opcional enquanto toca.
// Clique: painel do leitor; meio: tocar/pausar; scroll: faixa seguinte/anterior.
BarItem {
    id: root

    readonly property var cfg: Config.widgets.media

    shown: Media.active !== null && Media.title !== ""
    icon: Media.playing ? "music_note" : "pause"
    iconFill: Media.playing ? 1 : 0
    iconColor: Theme.primary
    text: Media.artist ? `${Media.title}  ·  ${Media.artist}` : Media.title
    maxTextWidth: cfg.maxWidth
    tooltip: `<b>${Media.title}</b>` + (Media.artist ? `\n${Media.artist}` : "") + (Media.active?.trackAlbum ? `\n<i>${Media.active.trackAlbum}</i>` : "") + `\n\n${Media.active?.identity ?? ""}`

    onMiddleClicked: Media.togglePlaying()
    popoutName: "media"
    popout: Component {
        MediaCard {}
    }
    onScrolled: direction => direction > 0 ? Media.previous() : Media.next()

    StyledText {
        visible: root.cfg.cava && Media.playing && cava.text !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: cava.text
        color: BarLayout.readable(Theme.primary, 3)
        font.family: Config.appearance.monoFont
    }

    // O cava.py do HyDE partilha um único processo cava entre todos os clientes.
    JsonStream {
        id: cava
        exec: "hyde-shell cava.py waybar --json"
        running: root.cfg.cava && Media.playing
    }
}
