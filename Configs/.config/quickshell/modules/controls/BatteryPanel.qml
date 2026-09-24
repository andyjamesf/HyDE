import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.services

// Bateria: carga, tempo restante, saúde e perfil de energia.
ColumnLayout {
    id: root

    width: 300
    spacing: 12

    RowLayout {
        spacing: 14

        MaterialIcon {
            icon: Battery.icon
            size: 44
            fill: 1
            color: Battery.low ? Theme.error : Battery.plugged ? Theme.success : Theme.primary
        }

        ColumnLayout {
            spacing: 0

            StyledText {
                text: `${Battery.percent}%`
                font.pixelSize: 28
                font.weight: Font.Light
            }

            StyledText {
                text: (Battery.charging ? "A carregar" : Battery.plugged ? "Ligado à corrente" : "Em bateria") + (Battery.secondsLeft > 0 ? ` · ${Utils.formatDuration(Battery.secondsLeft)} ${Battery.charging ? "até carregar" : "restantes"}` : "")
                color: Theme.textDim
            }
        }
    }

    StyledText {
        visible: Battery.device?.healthSupported ?? false
        text: `Saúde da bateria: ${Math.round(Battery.device?.healthPercentage ?? 0)}%`
        font.pixelSize: 11
        color: Theme.textFaint
    }

    SectionLabel {
        text: "Perfil de energia"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: PowerProfiles.hasPerformanceProfile ? [0, 1, 2] : [0, 1]

            Rectangle {
                id: seg

                required property int modelData
                readonly property bool current: Battery.profile === modelData

                Layout.fillWidth: true
                implicitHeight: 58
                radius: 16
                color: current ? Theme.primary : Theme.surfaceContainerHighest

                Behavior on color {
                    ColorAnim {}
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: ["energy_savings_leaf", "balance", "speed"][seg.modelData]
                        size: 20
                        fill: seg.current ? 1 : 0
                        color: seg.current ? Theme.onPrimary : Theme.text
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: ["Poupança", "Equilibrado", "Desempenho"][seg.modelData]
                        font.pixelSize: 11
                        color: seg.current ? Theme.onPrimary : Theme.text
                    }
                }

                StateLayer {
                    anchors.fill: parent
                    radius: seg.radius
                    onClicked: Battery.setProfile(seg.modelData)
                }
            }
        }
    }

    StyledText {
        visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        Layout.fillWidth: true
        text: "Desempenho limitado pelo sistema (temperatura ou portátil ao colo)."
        font.pixelSize: 11
        color: Theme.warning
        wrapMode: Text.WordWrap
    }
}
