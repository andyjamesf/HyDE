pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Bloqueio de sessão da shell (ext-session-lock) com autenticação PAM — a mesma configuração do
// hyprlock (/etc/pam.d/hyprlock), por isso aceita as mesmas credenciais.
//
// Entradas: `qs ipc call lock lock` (usado pelo hypridle e por `loginctl lock-session`) e
// `qs ipc call lock unlock` (usado pelo `loginctl unlock-session`; é a saída de emergência e tem o
// mesmo nível de confiança: qualquer processo do utilizador já pode fazer unlock-session).
// Com `lock.enabled: false` no config.json, bloquear usa o hyprlock do HyDE.
Singleton {
    id: root

    // O estado sobrevive a um reload da shell: o WlSessionLock novo retoma o bloqueio. Sem isto, um
    // reload com o ecrã bloqueado largava o lock e o Hyprland mostrava "lockscreen app died".
    property alias locked: persist.locked
    property bool authenticating: pam.active
    property string error: ""
    property int failures: 0
    // Palavra-passe à espera de ser pedida pelo PAM (só existe durante a autenticação).
    property string pending: ""

    function lock() {
        if (!Config.widgets.lock.enabled) {
            Utils.run("hyde-shell lockscreen.sh");
            return;
        }
        error = "";
        locked = true;
    }

    function unlock() {
        pending = "";
        error = "";
        failures = 0;
        if (pam.active)
            pam.abort();
        locked = false;
    }

    function submit(password) {
        if (!locked || pam.active || password === "")
            return;
        error = "";
        pending = password;
        pam.start();
    }

    PersistentProperties {
        id: persist
        reloadableId: "lockState"
        property bool locked: false
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onPamMessage: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            } else if (messageIsError) {
                root.error = message;
            }
        }

        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.failures++;
                root.error = result === PamResult.MaxTries ? "Too many attempts, wait a moment" : "Wrong password";
            }
        }

        onError: err => {
            root.pending = "";
            root.error = `Authentication error (${PamError.toString(err)})`;
        }
    }
}
