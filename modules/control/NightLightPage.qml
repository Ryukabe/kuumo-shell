import QtQuick
import "../../components"
import "../../styles"
import "../display"

// The Night Light page: a warm-to-cold temperature slider and a gamma slider.
// Moving either one turns Night Light on.
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout

    // The back arrow was tapped
    signal back()

    PageHeader {
        id: header
        layout: root.layout
        width: parent.width
        title: "Night Light"
        note: NightLightService.enabled ? "On" : "Off"
        onBack: root.back()
    }

    Column {
        anchors.top: header.bottom
        anchors.topMargin: root.layout.sectionGap
        width: parent.width
        spacing: root.layout.sectionGap

        // ── Temperature: warm on the left, cold on the right ──
        Column {
            width: parent.width
            spacing: Theme.spacingSm

            Text {
                text: "Temperature"
                color: Theme.fgMuted
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeXs
            }

            MoonSlider {
                layout: root.layout
                width: parent.width
                iconName: "thermostat"
                level: NightLightService.temperatureLevel
                valueText: NightLightService.temperature + "K"
                gradientTrack: true
                onMoved: value => NightLightService.setTemperatureLevel(value)
            }

            // "Warm" and "Cold" under the two ends of the track
            Item {
                width: parent.width
                height: warmLabel.implicitHeight

                Text {
                    id: warmLabel
                    x: root.layout.iconSize + root.layout.iconGap
                    text: "Warm"
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                }

                Text {
                    x: parent.width - root.layout.pctGap - root.layout.pctW - width
                    text: "Cold"
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                }
            }
        }

        // ── Gamma ──
        Column {
            width: parent.width
            spacing: Theme.spacingSm

            Text {
                text: "Gamma"
                color: Theme.fgMuted
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeXs
            }

            MoonSlider {
                layout: root.layout
                width: parent.width
                iconName: "tonality"
                level: NightLightService.gammaLevel
                valueText: NightLightService.gamma + "%"
                onMoved: value => NightLightService.setGammaLevel(value)
            }
        }
    }
}