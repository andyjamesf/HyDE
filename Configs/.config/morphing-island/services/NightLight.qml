pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Night light through the hyprsunset daemon (0.4, started by HyDE), controlled via Hyprland IPC:
// `hyprctl hyprsunset temperature <K>` turns it on, `hyprctl hyprsunset identity` turns it off.
// The state is REAL: it is read with `hyprctl hyprsunset temperature` (no argument, read-only),
// which returns the current temperature; in identity mode hyprsunset reports 6000 K, its neutral.
// There is no change signal and no polling: it is read at startup, after every action and when
// whoever shows the state calls refresh() (e.g. when opening the panel).
// Note: this does not update the state file of HyDE's script (~/.local/state/hyde/hyprsunset);
// HyDE's shortcut may therefore need two presses to toggle after using this.
Singleton {
    id: root

    // Temperature hyprsunset uses as identity (no filter).
    readonly property int _identityKelvin: 6000

    // Current temperature read from the daemon; -1 = unknown or daemon unreachable.
    property int _kelvin: -1
    // Prevents syncing `temperature` with the daemon from applying the same value again.
    property bool _syncing: false
    // Command waiting while another runs (only the latest matters, e.g. while dragging).
    property var _queued: null
    property bool _rereadAfter: false

    // "Present" = the daemon answers IPC (without it no action would have any effect).
    readonly property bool available: _kelvin > 0
    readonly property bool active: available && _kelvin !== _identityKelvin
    readonly property int currentTemperature: Math.max(0, _kelvin)
    // Temperature applied when turning on (ControlCenter.nightLightTemperature); with the light on,
    // changing it applies it right away.
    property int temperature: ControlCenter.nightLightTemperature

    function refresh() {
        if (reader.running)
            _rereadAfter = true; // the ongoing read may predate the last action
        else
            reader.running = true;
    }

    function set(on) {
        _run(on ? ["hyprctl", "--quiet", "hyprsunset", "temperature", String(_clampedTemperature())] : ["hyprctl", "--quiet", "hyprsunset", "identity"]);
    }

    function toggle() {
        set(!active);
    }

    function _clampedTemperature() {
        return Math.max(1000, Math.min(20000, Math.round(temperature)));
    }

    function _run(cmd) {
        if (writer.running) {
            _queued = cmd;
            return;
        }
        writer.command = cmd;
        writer.running = true;
    }

    onTemperatureChanged: {
        if (!_syncing && active)
            set(true);
    }

    Component.onCompleted: refresh()

    Process {
        id: reader
        command: ["hyprctl", "hyprsunset", "temperature"]
        onRunningChanged: {
            if (!running && root._rereadAfter) {
                root._rereadAfter = false;
                Qt.callLater(root.refresh);
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root._kelvin = /^\d+$/.test(t) ? parseInt(t) : -1;
                // With the light already on (e.g. by HyDE), adopt the temperature in use.
                if (root.active && root.temperature !== root._kelvin) {
                    root._syncing = true;
                    root.temperature = root._kelvin;
                    root._syncing = false;
                }
            }
        }
    }

    Process {
        id: writer
        onRunningChanged: {
            if (running)
                return;
            const next = root._queued;
            root._queued = null;
            if (next)
                Qt.callLater(root._run, next);
            else
                root.refresh();
        }
    }
}
