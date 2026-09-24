import qs.components
import qs.services

// Visualizador cava isolado (o widget de media também o pode mostrar embutido).
BarItem {
    shown: stream.text !== ""
    text: stream.text
    textColor: Theme.primary
    fontFamily: Config.appearance.monoFont

    JsonStream {
        id: stream
        exec: "hyde-shell cava.py waybar --json"
    }
}
