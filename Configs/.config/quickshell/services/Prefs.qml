pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Preferências escolhidas em runtime (menus, IPC), guardadas em ~/.local/state/quickshell/…/prefs.json.
// Ficam fora do config.json de propósito: esse vive no repositório de dotfiles e não deve ser
// reescrito pela shell.
Singleton {
    id: root

    // Layout da barra escolhido (vazio: usa o "layout" do config.json).
    property alias layout: adapter.layout
    // Origem das cores: "hyde" segue o HyDE (tema ou wallbash, conforme o modo do HyDE);
    // "wallpaper" usa sempre as cores extraídas do wallpaper atual.
    property alias colorSource: adapter.colorSource
    // Estilo do fundo das ilhas (ver BarLayout.pillStyles); vazio: usa o do config.json.
    property alias pillStyle: adapter.pillStyle
    // Opacidade do fundo das ilhas escolhida no menu (negativo: usa a do layout/config.json).
    property alias pillOpacity: adapter.pillOpacity
    // "Não incomodar": sem popups de notificações (exceto as críticas).
    property alias dnd: adapter.dnd
    // AI usage da barra aberto (true) ou recolhido atrás do botão (false).
    property alias aiExpanded: adapter.aiExpanded

    function save() {
        file.writeAdapter();
    }

    FileView {
        id: file
        path: Quickshell.statePath("prefs.json")
        printErrors: false
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string layout: ""
            property string colorSource: "hyde"
            property string pillStyle: ""
            property real pillOpacity: -1
            property bool dnd: false
            property bool aiExpanded: false
        }
    }
}
