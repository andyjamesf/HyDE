//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.config
import qs.services

// Morphing Island: a single floating island at the top of each screen that turns into a clock,
// an expanded bar, OSDs, notifications, the launcher, the control center, etc.
// Start: `qs -p ~/.config/morphing-island` (or `island on`, which swaps it with HyDE's shell).
// Tunables: config/ (see config/README.md).
ShellRoot {
    // Singletons are only created when something uses them: this starts the notification server now.
    readonly property int notificationCount: Notifications.count
    // The polkit agent must exist from startup (it registers with polkitd).
    readonly property bool polkitRegistered: Polkit.registered

    Variants {
        model: Quickshell.screens

        IslandWindow {}
    }

    // Lock screen (ext-session-lock + PAM): see services/Lock.qml.
    LockScreen {}

    // Volume, microphone and brightness changes (keys, apps, other panels) → OSD in the island of
    // the focused screen.
    Connections {
        target: Audio
        function onChangedByUser() {
            IslandController.showTransient(IslandState.volume);
        }
        function onMicChangedByUser() {
            if (OsdConfig.showMic)
                IslandController.showTransient(IslandState.mic);
        }
    }
    Connections {
        target: Brightness
        function onChangedByUser() {
            IslandController.showTransient(IslandState.brightness);
        }
    }

    // qs -p ~/.config/morphing-island ipc call lock <function> (hypridle, loginctl lock-session)
    IpcHandler {
        target: "lock"

        function lock(): void {
            Lock.lock();
        }
        // Same trust level as `loginctl unlock-session` (used by hypridle's unlock_cmd).
        function unlock(): void {
            Lock.unlock();
        }
        function isLocked(): bool {
            return Lock.locked;
        }
    }

    // qs -p ~/.config/morphing-island ipc call island <function>
    IpcHandler {
        target: "island"

        // Opens (or closes, if already open) a surface: launcher, controlcenter, theme…
        function open(mode: string): void {
            IslandController.open(mode);
        }
        function close(): void {
            IslandController.close();
        }
        // Hides/shows the pill (windows move up to the top); persisted (Prefs "pill.hidden").
        function hide(): void {
            Pill.setHidden(!Pill.hidden);
        }
        function pin(): void {
            IslandController.togglePin();
        }
        function mode(): string {
            return IslandController.mode || (IslandController.pinned ? "expanded" : "clock");
        }
        // Peace mode (no popups, history only); toggles and is persisted.
        function peace(): void {
            Notifications.togglePeace();
        }
        // Caffeine (idle inhibitor); toggles and is persisted.
        function caffeine(): void {
            Caffeine.toggle();
        }
        // Number of notifications in the history.
        function notifications(): string {
            return String(Notifications.count);
        }
        function clearNotifications(): void {
            Notifications.clear();
        }
        // Launcher without a keyboard: opens it (if not already open on this screen) and types the
        // query, prefix included ("=2+2", ":text", "fire").
        function launcher(query: string): void {
            const here = IslandController.mode === IslandState.launcher && IslandController.screen === IslandController.focusedScreen;
            // With a picker open, reopen the normal launcher (closing empties the picker).
            if (here && LauncherState.provider !== "")
                IslandController.close();
            if (IslandController.mode !== IslandState.launcher)
                IslandController.open(IslandState.launcher);
            LauncherState.query = query;
        }
        // Opens the launcher in a picker (services/Pickers.qml): windows, files, web, emoji, glyph,
        // bookmarks, quickapps, games, wallbash, animations, hyprlock, workflows, shaders, layouts.
        // An unknown name opens the normal launcher. With the launcher already open, switches picker.
        function pick(name: string): void {
            const known = Pickers.get(name) !== null;
            const here = IslandController.mode === IslandState.launcher && IslandController.screen === IslandController.focusedScreen;
            if (here && !known && LauncherState.provider !== "")
                IslandController.close();
            LauncherState.provider = known ? name : "";
            if (IslandController.mode !== IslandState.launcher || IslandController.screen !== IslandController.focusedScreen)
                IslandController.open(IslandState.launcher);
            else
                LauncherState.query = "";
        }
    }

    // Test/diagnostic hooks (read-only or harmless): qs -p ~/.config/morphing-island ipc call island-debug <function>
    IpcHandler {
        target: "island-debug"

        // Pretends the pointer is over the island of the focused screen (tests without a mouse).
        function hover(on: bool): void {
            IslandController.forceHover = on;
        }
        // "registered" if the island is the session's polkit agent.
        function polkit(): string {
            return Polkit.registered ? "registered" : "not registered";
        }
        // The latest notifications in the history (app · title · icon).
        function recentNotifications(): string {
            return Notifications.list.slice(0, 10).map(n => `${n.appName} · ${n.summary} · ${n.appIcon}`).join("\n");
        }
        // Control center: "page=<page> sliding=0|1 height=<px> wifi=… networks=<n>
        // bluetooth=… devices=<n> sinks=<n> sources=<n> media=0|1 notifications=<n>", or "closed".
        function ccState(): string {
            const m = IslandController.mode;
            return m === IslandState.controlCenter || IslandState.subviews.includes(m) ? ControlCenterState.status : "closed";
        }
        // Launcher/picker: "<mode> <result count> <selected title>" (e.g. "apps 3 Firefox",
        // "pick:windows 4 ~"), or "closed".
        function launcherState(): string {
            return IslandController.mode === IslandState.launcher ? LauncherState.status : "closed";
        }
        // Current Prefs overrides as JSON (services/Prefs.qml).
        function prefs(): string {
            return JSON.stringify(Prefs.values);
        }
        // Reloads a picker's data, as opening it does (asynchronous: call pickItems a moment later).
        function pickRefresh(name: string): string {
            const p = Pickers.get(name);
            if (!p)
                return "unknown picker";
            p.refresh();
            return "refreshing";
        }
        // A picker's entries for a query, one per line: "<index>\t<key>\t<title>\t<badge>".
        function pickItems(name: string, query: string): string {
            const p = Pickers.get(name);
            return p ? p.items(query).map((it, i) => `${i}\t${it.key ?? ""}\t${it.title ?? ""}\t${it.badge ?? ""}`).join("\n") : "unknown picker";
        }
        // Activates entry <index> of pickItems(name, query), as Enter would. Changes real state:
        // the bind tests restore it afterwards.
        function pickActivate(name: string, query: string, index: int): string {
            const p = Pickers.get(name);
            const it = p ? p.items(query)[index] : undefined;
            if (!it)
                return "no such entry";
            p.activate(it);
            return `activated ${it.key ?? it.title}`;
        }
    }
}
