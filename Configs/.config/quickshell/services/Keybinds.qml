pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Atalhos do Hyprland para o modo "Keys" do launcher (substitui o keybinds_hint do HyDE, que abria
// no rofi). Lidos de `hyprctl binds -j`; só os que têm descrição. A descrição do HyDE traz a
// categoria entre parênteses retos: "[Launcher|Apps] browser" → categoria "Launcher · Apps".
Singleton {
    id: root

    property var entries: []
    property bool loading: false

    // Bits do modmask do Hyprland, pela ordem em que se escrevem.
    readonly property var mods: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]
    readonly property var keyNames: ({
            "slash": "/",
            "backslash": "\\",
            "comma": ",",
            "period": ".",
            "semicolon": ";",
            "apostrophe": "'",
            "grave": "`",
            "minus": "-",
            "equal": "=",
            "bracketleft": "[",
            "bracketright": "]",
            "space": "Space",
            "return": "Enter",
            "escape": "Esc",
            "tab": "Tab",
            "delete": "Delete",
            "backspace": "Backspace",
            "print": "Print",
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓",
            "mouse:272": "Left click",
            "mouse:273": "Right click",
            "mouse:274": "Middle click",
            "mouse_up": "Scroll ↑",
            "mouse_down": "Scroll ↓",
            "alt_l": "Left Alt",
            "alt_r": "Right Alt",
            "super_l": "Super",
            "super_r": "Super",
            "xf86audioraisevolume": "Volume +",
            "xf86audiolowervolume": "Volume −",
            "xf86audiomute": "Mute",
            "xf86audiomicmute": "Mic mute",
            "xf86audioplay": "Play",
            "xf86audiopause": "Pause",
            "xf86audionext": "Next track",
            "xf86audioprev": "Previous track",
            "xf86monbrightnessup": "Brightness +",
            "xf86monbrightnessdown": "Brightness −"
        })

    function keyName(key) {
        const k = String(key);
        const named = keyNames[k.toLowerCase()];
        if (named)
            return named;
        if (/^code:\d+$/.test(k))
            return `Key ${k.slice(5)}`;
        if (k.length === 1)
            return k.toUpperCase();
        if (/^XF86/.test(k))
            return k.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
        return k.charAt(0).toUpperCase() + k.slice(1).toLowerCase();
    }

    // [ "Super", "Shift", "T" ]
    function keysOf(b) {
        const parts = mods.filter(m => (b.modmask & m[0]) !== 0).map(m => m[1]);
        parts.push(keyName(b.key));
        return parts;
    }

    // Teclas que são só modificadores (ex.: soltar o Alt no fim do Alt+Tab): fazem parte de outro
    // atalho e não se carregam sozinhas, por isso não aparecem na lista.
    readonly property var modifierKeys: ["alt_l", "alt_r", "super_l", "super_r", "control_l", "control_r", "shift_l", "shift_r"]

    // Um atalho por ação: combinações diferentes para a mesma coisa (Super+Q e Alt+F4 para fechar a
    // janela) ficam na mesma linha, em `combos`.
    function parse(json) {
        const byAction = {};
        const out = [];
        for (const b of JSON.parse(json)) {
            if (!b.has_description || !b.description || modifierKeys.includes(String(b.key).toLowerCase()))
                continue;
            const m = /^\[([^\]]*)\]\s*(.*)$/.exec(b.description);
            const category = m ? m[1].split("|").join(" · ") : "";
            const text = (m ? m[2] : b.description).trim();
            const keys = keysOf(b);
            const id = `${category}|${text}`;
            let entry = byAction[id];
            if (!entry) {
                entry = byAction[id] = {
                    title: text.charAt(0).toUpperCase() + text.slice(1),
                    category: category,
                    combos: [],
                    dispatcher: b.dispatcher,
                    arg: b.arg,
                    haystack: `${text} ${category}`.toLowerCase()
                };
                out.push(entry);
            }
            if (!entry.combos.some(c => c.join("+") === keys.join("+"))) {
                entry.combos.push(keys);
                entry.haystack += " " + keys.join(" ").toLowerCase();
            }
        }
        return out;
    }

    // Todas as palavras da pesquisa têm de aparecer (na descrição, na categoria ou nas teclas).
    function search(query) {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w);
        return words.length ? entries.filter(e => words.every(w => e.haystack.includes(w))) : entries;
    }

    // Com a configuração em Lua, cada atalho é o dispatcher "__lua" com o número da função no
    // registo do Lua (o `hyprctl dispatch __lua N` do HyDE já não funciona: o dispatch passou a
    // receber código Lua). Só se aceita um número, para nunca avaliar texto arbitrário.
    function run(entry) {
        if (entry.dispatcher === "__lua") {
            if (/^\d+$/.test(entry.arg))
                Quickshell.execDetached(["hyprctl", "eval", `debug.getregistry()[${entry.arg}]()`]);
        } else {
            Quickshell.execDetached(["hyprctl", "dispatch", entry.dispatcher, entry.arg]);
        }
    }

    function refresh() {
        loading = true;
        proc.running = true;
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.entries = root.parse(text);
                } catch (e) {
                    console.warn("keybinds:", e);
                }
                root.loading = false;
            }
        }
    }
}
