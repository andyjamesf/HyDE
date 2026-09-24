pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Estado da shell partilhado por todos os ecrãs.
Singleton {
    id: root

    property bool barHidden: false
    // Lido pelo IdleInhibitor de cada barra (o inibidor precisa de uma janela).
    property bool idleInhibited: false

    // Centro de controlo: aberto em que ecrã, e em que página ("" = principal, "wifi", "bluetooth", "audio").
    property bool controlCenterOpen: false
    property string controlCenterScreen: ""
    property string controlCenterPage: ""
    // Um clique fora fecha o painel (focus grab) e, se foi no botão da barra, o mesmo clique
    // voltaria a abri-lo; este instante permite ignorar esse segundo efeito.
    property real controlCenterClosedAt: 0

    // Pedido de abrir uma popout da barra por nome (IPC/atalhos): a barra do ecrã com foco abre-a.
    property string requestedPopout: ""
    // O widget da barra com a popout aberta (só pode haver uma).
    property var popoutOwner: null
    property string requestedPopoutScreen: ""

    // Menus e tooltips da barra pedidos por IPC (para testar sem rato): "nome" ou "nome:i:j" abre
    // o menu do widget e entra nos submenus i, j…; vazio fecha.
    property string requestedMenu: ""
    property string requestedTooltip: ""

    function requestMenu(spec) {
        requestedPopoutScreen = Hyprland.focusedMonitor?.name ?? "";
        requestedMenu = "";
        requestedMenu = spec;
    }

    function requestTooltip(name) {
        requestedPopoutScreen = Hyprland.focusedMonitor?.name ?? "";
        requestedTooltip = name;
    }

    function requestPopout(name) {
        requestedPopoutScreen = Hyprland.focusedMonitor?.name ?? "";
        requestedPopout = "";
        requestedPopout = name;
    }

    // Launcher: aberto em que ecrã e em que modo ("apps", "clipboard" ou "calc").
    // Editor da fotografia: a imagem escolhida (vazio = fechado) e o ecrã onde abre.
    property string avatarSource: ""
    property string avatarScreen: ""

    property bool launcherOpen: false
    property string launcherScreen: ""
    property string launcherMode: "apps"
    property bool powerMenuOpen: false
    property string powerMenuScreen: ""

    function toggleLauncher(mode, screen) {
        if (launcherOpen && launcherMode === (mode ?? "apps")) {
            launcherOpen = false;
            return;
        }
        launcherScreen = screen || (Hyprland.focusedMonitor?.name ?? "");
        launcherMode = mode ?? "apps";
        powerMenuOpen = false;
        closeControlCenter();
        launcherOpen = true;
    }

    function togglePowerMenu() {
        if (powerMenuOpen) {
            powerMenuOpen = false;
            return;
        }
        powerMenuScreen = Hyprland.focusedMonitor?.name ?? "";
        launcherOpen = false;
        closeControlCenter();
        powerMenuOpen = true;
    }

    function openControlCenter(page) {
        controlCenterScreen = Hyprland.focusedMonitor?.name ?? "";
        controlCenterPage = page ?? "";
        controlCenterOpen = true;
    }

    function closeControlCenter() {
        if (controlCenterOpen)
            controlCenterClosedAt = Date.now();
        controlCenterOpen = false;
    }

    function toggleControlCenter(page) {
        if (!controlCenterOpen && Date.now() - controlCenterClosedAt < 300)
            return;
        if (controlCenterOpen && (page ?? "") === controlCenterPage)
            closeControlCenter();
        else
            openControlCenter(page);
    }
}
