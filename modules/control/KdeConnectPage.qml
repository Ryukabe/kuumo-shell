import QtQuick
import "../../styles"
import "../phone"

// The KDE Connect page: the phone's name and status, its battery, and two actions.
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
        title: KdeConnectService.paired ? KdeConnectService.deviceName : "KDE Connect"
        note: KdeConnectService.reachable ? "Connected" : "Offline"
        noteShown: KdeConnectService.paired
        onBack: root.back()
    }

    // ── The phone ──
    Column {
        anchors.top: header.bottom
        anchors.topMargin: root.layout.sectionGap
        width: parent.width
        spacing: root.layout.sectionGap
        visible: KdeConnectService.paired

        // Battery ring and its text
        Row {
            spacing: root.layout.netIconGap

            PhoneIcon {
                size: root.layout.phoneIconSize
                color: Theme.fg
                level: KdeConnectService.batteryLevel
                active: KdeConnectService.reachable
                charging: KdeConnectService.charging
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: KdeConnectService.reachable && KdeConnectService.battery >= 0
                        ? KdeConnectService.battery + "%" : "—"
                    color: Theme.fg
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.DemiBold
                }

                Text {
                    text: !KdeConnectService.reachable ? "Not reachable"
                        : KdeConnectService.charging ? "Charging" : "On battery"
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                }
            }
        }

        // Actions (only while the phone is reachable)
        Row {
            spacing: root.layout.netActionGap

            PillButton {
                layout: root.layout
                text: "Find my phone"
                enabled: KdeConnectService.reachable
                onClicked: KdeConnectService.ring()
            }

            PillButton {
                layout: root.layout
                text: "Send ping"
                enabled: KdeConnectService.reachable
                onClicked: KdeConnectService.ping()
            }
        }
    }

    // Shown when no phone is paired yet
    Text {
        anchors.centerIn: parent
        width: parent.width - 2 * root.layout.netPad
        visible: !KdeConnectService.paired
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: "No phone paired yet. Pair one from the KDE Connect app on your phone."
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }
}