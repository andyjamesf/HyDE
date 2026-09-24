import QtQuick
import qs.services

// NumberAnimation com a duração e a curva por omissão da shell.
NumberAnimation {
    duration: Anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Anim.standard
}
