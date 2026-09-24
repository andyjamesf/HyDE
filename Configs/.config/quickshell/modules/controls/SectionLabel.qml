import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Título pequeno de uma secção dentro de um painel.
StyledText {
    Layout.fillWidth: true
    Layout.topMargin: 4
    font.pixelSize: 11
    font.weight: Font.Bold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 0.6
    color: Theme.textDim
}
