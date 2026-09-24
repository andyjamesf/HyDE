import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.services

// Launcher (substitui o rofi do HyDE): apps com pesquisa fuzzy, favoritos e frecência; clipboard
// (cliphist); calculadora. Escrever uma conta no modo apps mostra logo o resultado.
// Teclado: ↑/↓ escolher · Enter abrir/copiar · Tab muda de modo · Ctrl+F favorito ·
// Delete apaga do clipboard · Esc fecha.
PanelWindow {
    id: win

    required property ShellScreen modelData
    readonly property bool open: ShellState.launcherOpen && (ShellState.launcherScreen === "" || ShellState.launcherScreen === modelData.name)
    readonly property string mode: ShellState.launcherMode
    readonly property var modes: [
        {
            id: "apps",
            icon: "apps",
            label: "Apps"
        },
        {
            id: "clipboard",
            icon: "content_paste",
            label: "Clipboard"
        },
        {
            id: "calc",
            icon: "calculate",
            label: "Calculadora"
        }
    ]

    property string query: ""
    property int current: 0
    // Última posição do rato (global). A seleção só segue o rato quando ele se mexe mesmo: ao abrir
    // por baixo do cursor, ou quando a lista muda ao escrever, o "hover" não conta.
    // Durante a animação de entrada o cartão escala por baixo do cursor parado, o que gera
    // eventos de movimento falsos: ignoram-se os primeiros 300 ms e deslocações até 3 px.
    property point lastMouse: Qt.point(-1, -1)
    property real openedAt: 0

    function mouseMoved(item, x, y) {
        const g = item.mapToGlobal(x, y);
        if (Date.now() - openedAt < 300) {
            lastMouse = g;
            return false;
        }
        const moved = lastMouse.x >= 0 && (Math.abs(g.x - lastMouse.x) > 3 || Math.abs(g.y - lastMouse.y) > 3);
        if (moved || lastMouse.x < 0)
            lastMouse = g;
        return moved;
    }
    readonly property var calcResult: mode !== "clipboard" ? Calculator.evaluate(query) : null
    readonly property var results: {
        if (mode === "apps")
            return Apps.search(query).slice(0, 60);
        if (mode === "clipboard") {
            const q = query.trim().toLowerCase();
            return (q ? Clipboard.entries.filter(e => e.text.toLowerCase().includes(q)) : Clipboard.entries).slice(0, 100);
        }
        return [];
    }
    // Linhas: o resultado da conta (se houver) vem primeiro.
    readonly property var rows: (calcResult !== null ? [
            {
                kind: "calc",
                value: calcResult
            }
        ] : []).concat(results.map(r => ({
                kind: mode === "clipboard" ? "clip" : "app",
                value: r
            })))

    screen: modelData
    visible: true
    implicitWidth: 620
    implicitHeight: 560
    exclusiveZone: 0
    color: "transparent"
    mask: Region {
        item: win.open ? card : null
    }

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // A janela é criada só quando o launcher abre (poupa memória), por isso a preparação corre
    // tanto ao ser criada como se voltar a abrir.
    function init() {
        grabReady = false;
        if (open) {
            query = "";
            input.text = "";
            current = 0;
            lastMouse = Qt.point(-1, -1);
            openedAt = Date.now();
            if (mode === "clipboard")
                Clipboard.refresh();
            focusTimer.restart();
        }
    }

    Component.onCompleted: init()
    onOpenChanged: init()
    onModeChanged: {
        current = 0;
        if (open && mode === "clipboard")
            Clipboard.refresh();
    }
    onQueryChanged: current = 0

    function close() {
        ShellState.launcherOpen = false;
    }

    function setMode(m) {
        ShellState.launcherMode = m;
        input.forceActiveFocus();
    }

    function cycleMode(step) {
        const i = modes.findIndex(m => m.id === mode);
        setMode(modes[(i + step + modes.length) % modes.length].id);
    }

    function activate(row) {
        if (!row)
            return;
        if (row.kind === "app")
            Apps.launch(row.value);
        else if (row.kind === "clip")
            Clipboard.copy(row.value);
        else if (row.kind === "calc")
            Quickshell.clipboardText = Calculator.format(row.value);
        close();
    }

    Timer {
        id: focusTimer
        interval: 10
        onTriggered: input.forceActiveFocus()
    }

    // A grab só começa depois de a janela já estar aberta no ecrã (com foco de teclado exclusivo,
    // ativá-la no mesmo instante fazia o Hyprland cancelá-la logo, fechando o launcher).
    property bool grabReady: false

    Timer {
        running: win.open && !win.grabReady
        interval: 60
        onTriggered: win.grabReady = true
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open && win.grabReady
        onCleared: win.close()
    }

    Rectangle {
        id: card

        width: parent.width
        height: Math.min(parent.height, column.implicitHeight + 28)
        radius: Theme.shapeXL
        color: Theme.alpha(Theme.surfaceContainer, 0.96)
        border.width: 1
        border.color: Theme.border
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        // Visível logo ao abrir (a opacidade ainda está a 0): sem isso a área de cliques da janela
        // ficava vazia nesse instante e o Hyprland cancelava a focus grab, fechando o launcher.
        visible: win.open || opacity > 0

        Behavior on opacity {
            NumberAnim {
                duration: Anim.fast
            }
        }
        Behavior on scale {
            NumberAnim {
                easing.bezierCurve: Anim.emphasized
            }
        }

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: Theme.space4
            spacing: Theme.space3

            // Pesquisa
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: height / 2
                color: Theme.surfaceContainerHigh
                border.width: 2
                border.color: Theme.alpha(Theme.primary, 0.6)

                MaterialIcon {
                    id: modeIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    icon: win.modes.find(m => m.id === win.mode)?.icon ?? "search"
                    size: 22
                    color: Theme.primary
                }

                TextInput {
                    id: input
                    anchors.left: modeIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.onPrimary
                    font.family: Config.appearance.font
                    font.pixelSize: Theme.titleMedium
                    clip: true
                    onTextChanged: win.query = text

                    Keys.onEscapePressed: win.close()
                    Keys.onUpPressed: win.current = Math.max(0, win.current - 1)
                    Keys.onDownPressed: win.current = Math.min(win.rows.length - 1, win.current + 1)
                    Keys.onReturnPressed: win.activate(win.rows[win.current])
                    Keys.onEnterPressed: win.activate(win.rows[win.current])
                    Keys.onTabPressed: win.cycleMode(1)
                    Keys.onBacktabPressed: win.cycleMode(-1)
                    Keys.onPressed: event => {
                        const row = win.rows[win.current];
                        if (event.key === Qt.Key_PageDown) {
                            win.current = Math.min(win.rows.length - 1, win.current + 8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            win.current = Math.max(0, win.current - 8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier) && row?.kind === "app") {
                            Apps.toggleFavorite(row.value);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Delete && row?.kind === "clip") {
                            Clipboard.remove(row.value);
                            event.accepted = true;
                        }
                    }

                    StyledText {
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.mode === "clipboard" ? "Procurar no clipboard…" : win.mode === "calc" ? "Escreve uma conta, ex.: (2+3)*4^2" : "Procurar apps ou fazer contas…"
                        color: Theme.textFaint
                        font.pixelSize: Theme.titleMedium
                    }
                }
            }

            // Modos
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: win.modes

                    Rectangle {
                        id: chip

                        required property var modelData
                        readonly property bool current: modelData.id === win.mode

                        implicitWidth: chipRow.implicitWidth + 24
                        implicitHeight: 30
                        radius: height / 2
                        color: current ? Theme.primary : Theme.surfaceContainerHigh

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: chip.modelData.icon
                                size: 16
                                fill: chip.current ? 1 : 0
                                color: chip.current ? Theme.onPrimary : Theme.text
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: chip.modelData.label
                                font.pixelSize: Theme.labelMedium
                                color: chip.current ? Theme.onPrimary : Theme.text
                            }
                        }

                        StateLayer {
                            anchors.fill: parent
                            onClicked: win.setMode(chip.modelData.id)
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: "Tab muda de modo"
                    font.pixelSize: Theme.labelSmall
                    color: Theme.textFaint
                }
            }

            // Resultado grande do modo calculadora
            ColumnLayout {
                visible: win.mode === "calc"
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: win.calcResult !== null ? `= ${Calculator.format(win.calcResult)}` : win.query ? "…" : ""
                    font.pixelSize: Theme.displaySmall
                    font.weight: Font.Light
                    color: Theme.primary
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: win.calcResult !== null ? "Enter copia o resultado" : "Funções: sqrt, sin, cos, tan, log, ln, abs, round… · constantes pi, e · 20% de 50: 50*20%"
                    font.pixelSize: Theme.labelSmall
                    color: Theme.textFaint
                    wrapMode: Text.WordWrap
                }
            }

            // Resultados
            ListView {
                id: list
                visible: win.mode !== "calc"
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 400)
                clip: true
                model: win.rows
                currentIndex: win.current
                boundsBehavior: Flickable.StopAtBounds
                spacing: 2

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool selected: index === win.current

                    width: list.width
                    height: 52

                    // Fundo da linha selecionada, por baixo do ícone e do texto.
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.shapeMedium
                        color: row.selected ? Theme.primaryContainer : "transparent"

                        Behavior on color {
                            ColorAnim {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: mouse => {
                            if (win.mouseMoved(this, mouse.x, mouse.y))
                                win.current = row.index;
                        }
                        onClicked: win.activate(row.modelData)
                    }

                    // Ícone
                    Item {
                        id: lead
                        width: 36
                        height: 36
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            visible: row.modelData.kind === "app"
                            anchors.fill: parent
                            source: row.modelData.kind === "app" ? Apps.iconOf(row.modelData.value) : ""
                        }

                        MaterialIcon {
                            visible: row.modelData.kind !== "app"
                            anchors.centerIn: parent
                            icon: row.modelData.kind === "calc" ? "calculate" : row.modelData.value?.image ? "image" : "content_paste"
                            size: 22
                            color: Theme.primary
                        }
                    }

                    ColumnLayout {
                        anchors.left: lead.right
                        anchors.leftMargin: 12
                        anchors.right: trailing.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.kind === "app" ? row.modelData.value.name : row.modelData.kind === "calc" ? `= ${Calculator.format(row.modelData.value)}` : row.modelData.value.image ? "Imagem" : row.modelData.value.text
                            font.pixelSize: Theme.titleSmall
                            font.weight: row.selected ? Font.DemiBold : Font.Normal
                            color: row.selected ? Theme.onPrimaryContainer : Theme.text
                            maximumLineCount: 1
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: row.modelData.kind === "app" ? (row.modelData.value.genericName || row.modelData.value.comment || "") : row.modelData.kind === "calc" ? "Calculadora · Enter copia" : row.modelData.value.image ? row.modelData.value.text : ""
                            font.pixelSize: Theme.labelSmall
                            color: row.selected ? Theme.alpha(Theme.onPrimaryContainer, 0.75) : Theme.textDim
                        }
                    }

                    Row {
                        id: trailing
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        IconButton {
                            visible: row.modelData.kind === "app" && (row.selected || Apps.isFavorite(row.modelData.value))
                            icon: "star"
                            size: 30
                            checked: row.modelData.kind === "app" && Apps.isFavorite(row.modelData.value)
                            onClicked: Apps.toggleFavorite(row.modelData.value)
                        }

                        IconButton {
                            visible: row.modelData.kind === "clip" && row.selected
                            icon: "delete"
                            size: 30
                            onClicked: Clipboard.remove(row.modelData.value)
                        }
                    }
                }
            }

            StyledText {
                visible: win.mode !== "calc" && win.rows.length === 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                padding: 16
                text: win.mode === "clipboard" ? (Clipboard.loading ? "A carregar…" : "Clipboard vazio") : "Sem resultados"
                color: Theme.textFaint
            }
        }
    }
}
