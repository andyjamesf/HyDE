pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Aplicações instaladas (ficheiros .desktop): ícones por app id, pesquisa fuzzy para o launcher,
// favoritos e "frecência" (as mais usadas e mais recentes sobem na lista). O histórico de uso e
// os favoritos ficam em ~/.local/state/quickshell/…/launcher.json.
Singleton {
    id: root

    readonly property var applications: DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var favorites: store.favorites

    function entryFor(appId) {
        return appId ? DesktopEntries.heuristicLookup(appId) : null;
    }

    function iconFor(appId) {
        const entry = entryFor(appId);
        return Quickshell.iconPath(entry?.icon || appId.toLowerCase(), "application-x-executable");
    }

    function iconOf(entry) {
        return Quickshell.iconPath(entry?.icon || "", "application-x-executable");
    }

    function nameFor(appId) {
        return entryFor(appId)?.name || appId;
    }

    function isFavorite(entry) {
        return store.favorites.includes(entry.id);
    }

    function toggleFavorite(entry) {
        store.favorites = isFavorite(entry) ? store.favorites.filter(id => id !== entry.id) : store.favorites.concat([entry.id]);
        file.writeAdapter();
    }

    // Lança pelo app2unit do HyDE (como o rofi do HyDE): cada app fica na sua unidade systemd.
    function launch(entry, actionId) {
        const uses = Object.assign({}, store.uses);
        const u = uses[entry.id] ?? {
            count: 0,
            last: 0
        };
        uses[entry.id] = {
            count: u.count + 1,
            last: Date.now()
        };
        store.uses = uses;
        file.writeAdapter();
        Quickshell.execDetached(["hyde-shell", "app", "--", actionId ? `${entry.id}.desktop:${actionId}` : `${entry.id}.desktop`]);
    }

    // Frecência: usos, com mais peso para os recentes (meia-vida de uma semana).
    function frecency(entry) {
        const u = store.uses[entry.id];
        if (!u)
            return 0;
        const days = (Date.now() - u.last) / 86400000;
        return u.count * Math.pow(0.5, days / 7);
    }

    // Pontuação fuzzy de `q` em `text`: prefixo > início de palavra > substring > subsequência.
    function fuzzy(q, text) {
        if (!text)
            return 0;
        const t = text.toLowerCase();
        if (t === q)
            return 120;
        if (t.startsWith(q))
            return 100 - Math.min(20, t.length - q.length);
        const word = t.search(new RegExp(`(^|[\\s\\-_.])${q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
        if (word >= 0)
            return 85 - Math.min(15, word);
        const idx = t.indexOf(q);
        if (idx >= 0)
            return 70 - Math.min(20, idx);
        // Subsequência: todas as letras por ordem; perde pontos por cada salto.
        let ti = 0, gaps = 0, last = -1;
        for (const ch of q) {
            const found = t.indexOf(ch, ti);
            if (found < 0)
                return 0;
            if (last >= 0 && found > last + 1)
                gaps++;
            last = found;
            ti = found + 1;
        }
        return Math.max(1, 50 - gaps * 8 - Math.min(10, t.length - q.length));
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "") {
            // Sem pesquisa: favoritos, depois as mais usadas, depois o resto por ordem alfabética.
            const fav = applications.filter(e => isFavorite(e));
            const used = applications.filter(e => !isFavorite(e) && frecency(e) > 0).sort((a, b) => frecency(b) - frecency(a));
            const rest = applications.filter(e => !isFavorite(e) && frecency(e) === 0);
            return fav.concat(used, rest);
        }
        const scored = [];
        for (const e of applications) {
            const s = Math.max(fuzzy(q, e.name), fuzzy(q, e.genericName) * 0.75, fuzzy(q, (e.keywords ?? []).join(" ")) * 0.65, fuzzy(q, e.id) * 0.6, fuzzy(q, e.comment) * 0.4);
            if (s > 0)
                scored.push({
                    e,
                    s: s + Math.min(25, frecency(e) * 4) + (isFavorite(e) ? 10 : 0)
                });
        }
        return scored.sort((a, b) => b.s - a.s).map(x => x.e);
    }

    FileView {
        id: file
        path: Quickshell.statePath("launcher.json")
        printErrors: false
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property var uses: ({})
            property var favorites: []
        }
    }
}
