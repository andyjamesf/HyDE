pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Corre um comando de shell sem esperar por ele (como os on-click da Waybar).
    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // Os scripts do HyDE produzem markup Pango; o StyledText do Qt só conhece <font color>.
    // `mapColor` (opcional) ajusta cada cor embutida (ex.: para ter contraste com o fundo).
    function pango(s, mapColor) {
        if (!s)
            return "";
        return String(s).replace(/<span([^>]*)>/g, (_, attrs) => {
            const c = /(?:foreground|fgcolor|color)=['"]([^'"]+)['"]/.exec(attrs);
            return c ? `<font color="${mapColor ? mapColor(c[1]) : c[1]}">` : "<font>";
        }).replace(/<\/span>/g, "</font>").replace(/ {2,}/g, m => "&nbsp;".repeat(m.length)).replace(/\n/g, "<br>");
    }

    // Data/hora formatada na língua do config.json (o locale do sistema pode ser inglês).
    function formatDate(date, format) {
        return date.toLocaleString(Qt.locale(Config.appearance.locale), format);
    }

    function dayName(day, format) {
        return Qt.locale(Config.appearance.locale).dayName(day, format);
    }

    // Escolhe um elemento de uma lista ordenada por nível (0..100), como a Waybar faz com format-icons.
    function level(list, percent) {
        return list[Math.max(0, Math.min(list.length - 1, Math.floor(percent * list.length / 101)))];
    }

    // "agora", "há 5 min", "há 2 h", ou a hora/data para coisas mais antigas.
    function relativeTime(date) {
        const s = (Date.now() - date.getTime()) / 1000;
        if (s < 60)
            return "agora";
        if (s < 3600)
            return `há ${Math.floor(s / 60)} min`;
        if (s < 6 * 3600)
            return `há ${Math.floor(s / 3600)} h`;
        const today = new Date();
        return date.toDateString() === today.toDateString() ? formatDate(date, "HH:mm") : formatDate(date, "d MMM, HH:mm");
    }

    function formatDuration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB"];
        let i = 0;
        while (bytes >= 1024 && i < units.length - 1) {
            bytes /= 1024;
            i++;
        }
        return `${bytes.toFixed(i > 1 ? 1 : 0)} ${units[i]}`;
    }
}
