pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Estado do Hyprland que os widgets precisam, já filtrado e ordenado.
Singleton {
    id: root

    // Workspaces normais (os especiais têm id negativo), por ordem.
    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel

    // A config do Hyprland está em Lua, onde os dispatchers são expressões `hl.dsp.*`.
    function dispatchFocusWorkspace(target) {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({workspace="${target}"})` : `workspace ${target}`);
    }

    function toplevelsOn(workspaceId) {
        return Hyprland.toplevels.values.filter(t => t.workspace?.id === workspaceId);
    }

    function appIdOf(toplevel) {
        return toplevel?.wayland?.appId || toplevel?.lastIpcObject?.class || "";
    }
}
