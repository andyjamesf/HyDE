import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Bloqueio de sessão: enquanto Lock.locked, o compositor mostra só estas superfícies (uma por
// monitor) e nada mais recebe teclado ou rato.
WlSessionLock {
    locked: Lock.locked

    WlSessionLockSurface {
        color: "black"

        LockSurface {}
    }
}
