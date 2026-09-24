pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Mantém o rofi do HyDE (atalhos de teclado, escolha de wallpaper, tema, animações, clipboard…)
// com o aspeto dos painéis da shell: o mesmo fundo e opacidade, o mesmo contorno discreto (em vez
// da borda na cor de acento) e a mesma cor de seleção do launcher.
//
// Todos os estilos do HyDE importam ~/.config/rofi/theme.rasi, que o HyDE reescreve a cada troca de
// tema. A shell escreve-o com as suas cores sempre que a paleta muda e volta a escrevê-lo se o HyDE
// o substituir (o ficheiro é gerado e não está no repositório).
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/rofi/theme.rasi`
    property string written: ""

    function hex(c, a) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return `#${h(c.r)}${h(c.g)}${h(c.b)}${h(a ?? 1)}`;
    }

    function rasi() {
        const r = Theme.toRoles;
        return `/* Gerado pela shell Quickshell (services/Rofi.qml): as cores dos painéis da shell. */
* {
    main-bg:            ${hex(r.surfaceContainer, 0.96)};
    main-fg:            ${hex(r.text)};
    main-br:            ${hex(r.outlineVariant, 0.6)};
    main-ex:            ${hex(r.primary)};
    select-bg:          ${hex(r.primaryContainer)};
    select-fg:          ${hex(r.onPrimaryContainer)};
    separatorcolor:     transparent;
    border-color:       transparent;
}
`;
    }

    function apply() {
        const text = rasi();
        if (file.text() === text)
            return;
        written = text;
        file.setText(text);
    }

    Connections {
        target: Theme
        function onToRolesChanged() {
            root.apply();
        }
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        blockLoading: true
        // O HyDE escreveu o dele (troca de tema): repõe-se o da shell.
        onFileChanged: {
            reload();
            if (text() !== root.written)
                root.apply();
        }
    }

    Component.onCompleted: apply()
}
