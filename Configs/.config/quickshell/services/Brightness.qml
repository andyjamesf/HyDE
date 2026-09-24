pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Brilho do ecrã. Não há API nativa no Quickshell, por isso:
// - leitura: o ficheiro do sysfs, com FileView;
// - deteção de mudanças: o kernel emite um uevent "change" em cada escrita no backlight
//   (testado neste portátil), lido com `udevadm monitor` — evita polling, e apanha também as
//   mudanças feitas pelas teclas/HyDE (brightnesscontrol.sh);
// - escrita: brightnessctl, porque o sysfs só é gravável por root (o brightnessctl usa o logind).
Singleton {
    id: root

    property string device
    property real max: 0
    property real percent: -1
    readonly property bool available: device !== "" && percent >= 0

    readonly property string icon: percent < 34 ? "brightness_low" : percent < 67 ? "brightness_medium" : "brightness_high"

    function set(p) {
        p = Math.max(1, Math.min(100, Math.round(p)));
        percent = p; // resposta imediata; o uevent confirma logo a seguir
        Quickshell.execDetached(["brightnessctl", "-q", "set", `${p}%`]);
    }

    function change(delta) {
        set(percent + delta);
    }

    // "amdgpu_bl1,backlight,65535,100%,65535"
    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: SplitParser {
            onRead: line => {
                const f = line.split(",");
                root.device = f[0];
                root.max = parseFloat(f[4]);
            }
        }
    }

    FileView {
        id: current
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: if (root.max > 0)
            root.percent = Math.round(parseFloat(text()) * 100 / root.max)
    }

    Process {
        running: root.device !== ""
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("change"))
                    current.reload();
            }
        }
    }
}
