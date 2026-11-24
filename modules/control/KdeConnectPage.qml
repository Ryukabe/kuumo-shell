import QtQuick
import "../../styles"
import "../phone"

// The KDE Connect page: a card with the phone's battery, status and connection, a row of
// round buttons (find the phone, ping, send the clipboard, look again), and a card that opens
// the KDE Connect app.
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout

    // The back arrow was tapped
    signal back()

    // What each round button does
    function runTile(id) {
        if (id === "ring") KdeConnectService.ring()
        else if (id === "ping") KdeConnectService.ping()
        else if (id === "clipboard") KdeConnectService.sendClipboard()
        else if (id === "refresh") KdeConnectService.rescan()
    }

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
    Item {
        id: content
        anchors.top: header.bottom
        anchors.topMargin: root.layout.rowGap
        anchors.bottom: parent.bottom
        width: parent.width
        visible: KdeConnectService.paired

        Column {
            id: column
            width: parent.width
            spacing: root.layout.rowGap

            // The card: the phone with its battery ring, and the numbers beside it
            Rectangle {
                width: parent.width
                height: root.layout.phoneCardH
                radius: root.layout.phoneCardRadius
                color: Theme.subBg
                border.width: root.layout.btnBorder
                border.color: Theme.border

                PhoneIcon {
                    id: bigIcon
                    x: root.layout.phoneCardPad
                    anchors.verticalCenter: parent.verticalCenter
                    size: root.layout.phoneIconSize
                    color: Theme.fg
                    ringEnabled: true
                    level: KdeConnectService.batteryLevel
                    active: KdeConnectService.reachable
                    charging: KdeConnectService.charging
                }

                Column {
                    anchors.left: bigIcon.right
                    anchors.leftMargin: root.layout.phoneCardPad
                    anchors.right: parent.right
                    anchors.rightMargin: root.layout.phoneCardPad
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingSm

                    Text {
                        text: KdeConnectService.reachable && KdeConnectService.battery >= 0
                            ? KdeConnectService.battery + "%" : "—"
                        color: bigIcon.low ? Theme.red : Theme.fg
                        font.family: Theme.fontText
                        font.pixelSize: root.layout.phonePctSize
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: !KdeConnectService.reachable ? "Not reachable"
                            : KdeConnectService.charging ? "Charging" : "On battery"
                        color: Theme.fgMuted
                        font.family: Theme.fontText
                        font.pixelSize: Theme.fontSizeSm
                    }

                    // The phone's mobile network, when KDE Connect reports it
                    Row {
                        spacing: Theme.spacingSm
                        visible: KdeConnectService.reachable
                            && (KdeConnectService.networkType !== "" || KdeConnectService.signalBars >= 0)

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.layout.signalBarGap
                            visible: KdeConnectService.signalBars >= 0

                            Repeater {
                                model: 4

                                delegate: Item {
                                    id: bar
                                    required property int index

                                    width: root.layout.signalBarW
                                    height: root.layout.signalBarH

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: bar.height * (bar.index + 1) / 4
                                        radius: width / 2
                                        color: bar.index < KdeConnectService.signalBars
                                            ? Theme.fg : Qt.alpha(Theme.fg, Theme.dimOpacity)
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: KdeConnectService.networkType !== ""
                            text: KdeConnectService.networkType
                            color: Theme.fgMuted
                            font.family: Theme.fontText
                            font.pixelSize: Theme.fontSizeXs
                        }
                    }
                }
            }

            // The round buttons, in the same style as the control center's
            Row {
                id: tiles
                width: parent.width

                Repeater {
                    model: [
                        { id: "ring", label: "Find phone", icon: "phonelink_ring", needsPhone: true },
                        { id: "ping", label: "Ping", icon: "sensors", needsPhone: true },
                        { id: "clipboard", label: "Clipboard", icon: "send_to_mobile", needsPhone: true },
                        { id: "refresh", label: "Refresh", icon: "refresh", needsPhone: false }
                    ]

                    delegate: MoonButton {
                        id: tile
                        required property var modelData

                        layout: root.layout
                        width: tiles.width / root.layout.tileSlots
                        lit: KdeConnectService.lastAction === tile.modelData.id
                        label: tile.modelData.label
                        enabled: !tile.modelData.needsPhone || KdeConnectService.reachable
                        opacity: enabled ? 1 : Theme.dimOpacity
                        onClicked: root.runTile(tile.modelData.id)

                        Text {
                            anchors.centerIn: parent
                            text: tile.modelData.icon
                            color: tile.iconColor
                            font.family: Theme.fontIcon
                            font.pixelSize: root.layout.tileIconSize
                        }
                    }
                }
            }
        }

        // What just happened; it fades out after a moment
        Text {
            id: noticeText
            property string held: ""

            anchors.top: column.bottom
            anchors.topMargin: root.layout.rowGap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: held
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
            opacity: KdeConnectService.notice !== "" ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
            }

            Connections {
                target: KdeConnectService
                function onNoticeChanged() {
                    if (KdeConnectService.notice !== "") noticeText.held = KdeConnectService.notice
                }
            }
        }

        // Opens the KDE Connect app, for what the island cannot do (files, messages, ...)
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.layout.cardH
            radius: root.layout.phoneCardRadius
            color: Qt.tint(Theme.subBg, Qt.alpha(Theme.border, appArea.containsMouse ? 1 : 0))
            border.width: root.layout.btnBorder
            border.color: Theme.border
            scale: appArea.pressed ? Motion.pressScale : 1

            Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
            Behavior on scale {
                NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
            }

            Text {
                id: appIcon
                x: root.layout.netPad
                anchors.verticalCenter: parent.verticalCenter
                text: "open_in_new"
                color: Theme.fgMuted
                font.family: Theme.fontIcon
                font.pixelSize: root.layout.cardIconSize
            }

            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: root.layout.netIconGap
                anchors.right: chevron.left
                anchors.rightMargin: root.layout.netIconGap
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: "KDE Connect app"
                    color: Theme.fg
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeSm
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: "Files, messages and more"
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                    elide: Text.ElideRight
                }
            }

            Text {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: root.layout.netPad
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                color: Theme.fgMuted
                font.family: Theme.fontIcon
                font.pixelSize: root.layout.cardIconSize
            }

            MouseArea {
                id: appArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: KdeConnectService.openApp()
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