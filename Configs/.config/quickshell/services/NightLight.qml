pragma Singleton
import QtQuick
import Quickshell
import qs.components

// Luz noturna através do hyprsunset do HyDE (mantém o estado e as predefinições do HyDE).
// Não há sinal de mudança: o estado é lido no arranque, depois de cada ação e quando algum
// painel que o mostra abre (refresh()).
Singleton {
    id: root

    readonly property bool active: state.alt !== "" && state.alt !== "inactive"
    readonly property string tooltip: state.tooltip

    function refresh() {
        state.refresh();
    }

    function run(args) {
        Utils.run(`hyde-shell hyprsunset ${args}`);
        refreshSoon.restart();
    }

    function toggle() {
        run("-t");
    }

    function setTemperature(kelvin) {
        run(`--cm temp -s ${kelvin}`);
    }

    JsonStream {
        id: state
        exec: "hyde-shell hyprsunset -rq"
        interval: -1
    }

    Timer {
        id: refreshSoon
        interval: 700
        onTriggered: state.refresh()
    }
}
