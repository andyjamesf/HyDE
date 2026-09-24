pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Leitores de media (MPRIS nativo). O leitor "ativo" é o que está a tocar; se nenhum estiver,
// o último que tocou; se não houver histórico, o primeiro da lista.
Singleton {
    id: root

    // O playerctld é um proxy para os outros leitores; mostrá-lo duplicaria o leitor ativo.
    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
    property MprisPlayer lastPlaying: null
    readonly property MprisPlayer active: players.find(p => p.isPlaying) ?? (players.includes(lastPlaying) ? lastPlaying : players[0] ?? null)

    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""

    onActiveChanged: if (active?.isPlaying)
        lastPlaying = active

    Connections {
        target: root.active
        function onIsPlayingChanged() {
            if (root.active?.isPlaying)
                root.lastPlaying = root.active;
        }
    }

    function togglePlaying() {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }

    function next() {
        if (active?.canGoNext)
            active.next();
    }

    function previous() {
        if (active?.canGoPrevious)
            active.previous();
    }
}
