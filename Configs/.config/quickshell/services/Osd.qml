pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// OSD de volume, microfone e brilho. Reage às mudanças nos serviços (Pipewire e o uevent do
// backlight), por isso aparece venha a mudança de onde vier: teclas do HyDE, barra, apps.
// Exceções (o hypridle baixa o brilho para 1% ao fim de 60 s e repõe-no no regresso):
//  - mudanças enquanto o utilizador está inativo, ou logo a seguir a voltar;
//  - mudanças de brilho de ou para ≤ 2% (o nível de escurecimento), venham de onde vierem.
Singleton {
    id: root

    property string kind: ""      // "volume" | "mic" | "brightness"
    property bool visible: false
    // A janela do OSD só existe enquanto é precisa (visível ou a desaparecer).
    readonly property bool needed: visible || fadeOut.running
    // Durante o arranque e ao trocar de dispositivo os valores "mudam" sem ninguém mexer.
    property bool armed: false
    property int lastBrightness: -1

    readonly property real value: kind === "brightness" ? Brightness.percent / 100 : kind === "mic" ? (Audio.micMuted ? 0 : Audio.micVolume) : (Audio.muted ? 0 : Audio.volume)
    readonly property string icon: kind === "brightness" ? Brightness.icon : kind === "mic" ? Audio.micIcon : Audio.icon
    readonly property bool muted: kind === "volume" ? Audio.muted : kind === "mic" ? Audio.micMuted : false

    function show(k) {
        if (!armed || !Config.widgets.osd.enabled || idle.isIdle)
            return;
        // O hypridle repõe o brilho no instante em que se volta: essa mudança não conta.
        if (k === "brightness" && resumeGrace.running)
            return;
        kind = k;
        visible = true;
        hideTimer.restart();
    }

    function disarmBriefly() {
        armed = false;
        arm.restart();
    }

    // Inativo há 20 s: bem antes do escurecimento do hypridle (60 s). Ignora os inibidores
    // (cafeína, vídeos): com eles ativos o hypridle também não mexe no brilho.
    IdleMonitor {
        id: idle
        timeout: 20
        respectInhibitors: false
        onIsIdleChanged: {
            console.debug("osd: idle =", isIdle);
            if (!isIdle)
                resumeGrace.restart();
        }
    }

    Timer {
        id: resumeGrace
        interval: 800
    }

    Timer {
        id: hideTimer
        interval: Config.widgets.osd.timeout
        onTriggered: {
            root.visible = false;
            fadeOut.restart();
        }
    }

    Timer {
        id: fadeOut
        interval: 400
    }

    Timer {
        id: arm
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.show("volume");
        }
        function onMutedChanged() {
            root.show("volume");
        }
        function onMicMutedChanged() {
            root.show("mic");
        }
        function onSinkChanged() {
            root.disarmBriefly();
        }
        function onSourceChanged() {
            root.disarmBriefly();
        }
    }

    Connections {
        target: Brightness
        function onPercentChanged() {
            const previous = root.lastBrightness;
            root.lastBrightness = Brightness.percent;
            if (previous >= 0 && (previous <= 2 || Brightness.percent <= 2)) {
                console.debug("osd: brightness", previous, "→", Brightness.percent, "ignored (dimming)");
                return;
            }
            root.show("brightness");
        }
    }
}
