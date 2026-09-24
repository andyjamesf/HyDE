//@ pragma UseQApplication
// Shell Quickshell para o HyDE. Arranca com `qs` (é a config por omissão em ~/.config/quickshell).
// Controlo externo: `qs ipc call <alvo> <função>`; `qs ipc show` lista tudo.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.bar
import qs.modules.controlcenter
import qs.modules.notifications
import qs.modules.osd
import qs.modules.launcher
import qs.modules.powermenu
import qs.modules.lock

ShellRoot {
    // Os singletons só são criados quando alguém os usa; estes têm de existir desde o arranque
    // (os eventos do calendário e o servidor de notificações).
    readonly property var agenda: Agenda
    readonly property var notifs: Notifs

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        ControlCenter {}
    }

    // Popups e OSD também só existem quando há algo a mostrar, no ecrã com foco.
    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: popupLoader
            required property ShellScreen modelData
            active: Notifs.popups.length > 0 && (Hyprland.focusedMonitor?.name ?? "") === modelData.name

            NotificationPopups {
                modelData: popupLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: osdLoader
            required property ShellScreen modelData
            active: Osd.needed && (Hyprland.focusedMonitor?.name ?? "") === modelData.name

            OsdWindow {
                modelData: osdLoader.modelData
            }
        }
    }

    // Launcher e power menu só existem enquanto estão abertos, e só no ecrã onde abriram: cada
    // janela tem o seu contexto gráfico, e mantê-las todas criadas custava centenas de MB.
    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: launcherLoader
            required property ShellScreen modelData
            active: ShellState.launcherOpen && ShellState.launcherScreen === modelData.name

            Launcher {
                modelData: launcherLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: powerLoader
            required property ShellScreen modelData
            active: ShellState.powerMenuOpen && ShellState.powerMenuScreen === modelData.name

            PowerMenu {
                modelData: powerLoader.modelData
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            ShellState.toggleLauncher("apps");
        }
        function clipboard(): void {
            ShellState.toggleLauncher("clipboard");
        }
        function calc(): void {
            ShellState.toggleLauncher("calc");
        }
        function close(): void {
            ShellState.launcherOpen = false;
        }
        // Abre num monitor específico (ex.: "DP-1").
        function openOn(screen: string): void {
            ShellState.launcherOpen = false;
            ShellState.toggleLauncher("apps", screen);
        }
    }

    LockScreen {}

    IpcHandler {
        target: "lock"

        function lock(): void {
            Lock.lock();
        }
        // Mesmo nível de confiança que `loginctl unlock-session` (usado pelo unlock_cmd do hypridle).
        function unlock(): void {
            Lock.unlock();
        }
        function isLocked(): bool {
            return Lock.locked;
        }
    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            ShellState.togglePowerMenu();
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): void {
            Notifs.toggleDnd();
        }
        function clear(): void {
            Notifs.clear();
        }
        function open(): void {
            ShellState.openControlCenter("notifications");
        }
        function toggle(): void {
            ShellState.toggleControlCenter("notifications");
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void {
            ShellState.toggleControlCenter("");
        }
        function open(): void {
            ShellState.openControlCenter("");
        }
        function close(): void {
            ShellState.closeControlCenter();
        }
        // "wifi", "bluetooth" ou "audio"
        function page(name: string): void {
            ShellState.openControlCenter(name);
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            ShellState.barHidden = !ShellState.barHidden;
        }
        function show(): void {
            ShellState.barHidden = false;
        }
        function hide(): void {
            ShellState.barHidden = true;
        }
        function layout(name: string): void {
            BarLayout.select(name);
        }
        function next(): void {
            BarLayout.cycle(1);
        }
        function prev(): void {
            BarLayout.cycle(-1);
        }
        // "calendar", "media", "audio", "network", "bluetooth", "battery" ou "brightness"
        function popout(name: string): void {
            ShellState.requestPopout(name);
        }
        // Fundo das ilhas: surface, tint, container, accent, glass, outline ou "#rrggbb".
        function pill(style: string): void {
            BarLayout.setPillStyle(style);
        }
        function opacity(value: real): void {
            BarLayout.setPillOpacity(value);
        }
        // Mostra/recolhe o uso dos agentes de IA na barra.
        function agents(): void {
            Prefs.aiExpanded = !Prefs.aiExpanded;
            Prefs.save();
        }
        function layouts(): string {
            return BarLayout.names.map(n => (n === BarLayout.current ? "* " : "  ") + n).join("\n");
        }
    }

    IpcHandler {
        target: "colors"

        // "hyde" (segue o HyDE) ou "wallpaper" (cores do wallpaper atual).
        function source(name: string): void {
            Theme.setColorSource(name);
        }
        function toggle(): void {
            Theme.setColorSource(Prefs.colorSource === "wallpaper" ? "hyde" : "wallpaper");
        }
    }

    IpcHandler {
        target: "idle"

        function toggle(): void {
            ShellState.idleInhibited = !ShellState.idleInhibited;
        }
        function isInhibited(): bool {
            return ShellState.idleInhibited;
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            Brightness.change(Config.widgets.brightness.step);
        }
        function down(): void {
            Brightness.change(-Config.widgets.brightness.step);
        }
        function set(percent: int): void {
            Brightness.set(percent);
        }
    }

    IpcHandler {
        target: "shell"

        function reload(): void {
            Quickshell.reload(true);
        }
    }
}
