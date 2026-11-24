import QtQuick
import "../.." as Root
import "../../styles"
import "../phone"

// The KDE Connect page: a card with the phone's name, battery, status and connection, a row
// of round buttons (find the phone, ping, send the clipboard, look again), a strip you can
// drop files on, and a card that opens the KDE Connect app.
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
        title: "KDE Connect"
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

        // Files dropped anywhere on the page go to the phone
        DropArea {
            id: fileDrop
            anchors.fill: parent
            enabled: KdeConnectService.reachable && Root.Config.kdeConnectDrop

            onEntered: drag => {
                if (KdeConnectService.localPaths(drag.urls).length === 0) drag.accepted = false
            }
            onDropped: drop => {
                drop.accept(Qt.CopyAction)
                KdeConnectService.sendFiles(drop.urls)
            }
        }

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

                    // The percentage, and on the right the phone's name. With more than one
                    // phone paired, tapping the name switches to the next phone.
                    Item {
                        width: parent.width
                        height: pctText.implicitHeight

                        Text {
                            id: pctText
                            anchors.verticalCenter: parent.verticalCenter
                            text: KdeConnectService.reachable && KdeConnectService.battery >= 0
                                ? KdeConnectService.battery + "%" : "—"
                            color: bigIcon.low ? Theme.red : Theme.fg
                            font.family: Theme.fontText
                            font.pixelSize: root.layout.phonePctSize
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            id: chip

                            readonly property bool multiple: KdeConnectService.devices.length > 1
                            readonly property real swapSpace: chip.multiple ? swapIcon.implicitWidth + Theme.spacingSm : 0

                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, Math.min(
                                chipName.implicitWidth + chip.swapSpace + 2 * root.layout.phoneChipPad,
                                parent.width - pctText.width - Theme.spacingSm))
                            height: root.layout.phoneChipH
                            radius: height / 2
                            color: Qt.tint(Theme.elevatedBg, Qt.alpha(Theme.border, chipArea.containsMouse ? 1 : 0))
                            border.width: root.layout.btnBorder
                            border.color: Theme.border
                            scale: chipArea.pressed ? Motion.pressScale : 1

                            Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
                            Behavior on scale {
                                NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
                            }

                            Text {
                                id: chipName
                                x: root.layout.phoneChipPad
                                anchors.verticalCenter: parent.verticalCenter
                                width: chip.width - 2 * root.layout.phoneChipPad - chip.swapSpace
                                elide: Text.ElideRight
                                text: KdeConnectService.deviceName
                                color: Theme.fg
                                font.family: Theme.fontText
                                font.pixelSize: Theme.fontSizeXs
                            }

                            Text {
                                id: swapIcon
                                anchors.right: parent.right
                                anchors.rightMargin: root.layout.phoneChipPad
                                anchors.verticalCenter: parent.verticalCenter
                                visible: chip.multiple
                                text: "swap_horiz"
                                color: Theme.fgMuted
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                enabled: chip.multiple
                                hoverEnabled: true
                                cursorShape: chip.multiple ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: KdeConnectService.nextDevice()
                            }
                        }
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

        // The drop strip: says what to do, lights up while you drag a file over the page,
        // and shows what just happened (sending, sent, ...)
        Rectangle {
            id: strip
            anchors.top: column.bottom
            anchors.topMargin: root.layout.rowGap
            width: parent.width
            height: root.layout.dropH
            visible: Root.Config.kdeConnectDrop || KdeConnectService.notice !== ""
            radius: height / 2
            color: fileDrop.containsDrag ? Theme.elevatedBg : Theme.subBg
            border.width: root.layout.btnBorder
            border.color: fileDrop.containsDrag ? Theme.accent : Theme.border

            Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
            Behavior on border.color { ColorAnimation { duration: Motion.hoverFade } }

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingSm

                Text {
                    id: stripIcon
                    anchors.verticalCenter: parent.verticalCenter
                    text: "upload_file"
                    color: fileDrop.containsDrag ? Theme.fg : Theme.fgMuted
                    font.family: Theme.fontIcon
                    font.pixelSize: root.layout.iconSize
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth,
                        strip.width - 2 * root.layout.phoneChipPad - stripIcon.width - Theme.spacingSm)
                    elide: Text.ElideRight
                    text: fileDrop.containsDrag ? "Release to send to " + KdeConnectService.deviceName
                        : KdeConnectService.notice !== "" ? KdeConnectService.notice
                        : !KdeConnectService.reachable ? "Phone not reachable"
                        : "Drop files here to send them"
                    color: fileDrop.containsDrag ? Theme.fg : Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                }
            }
        }

        // Opens the KDE Connect app, for what the island cannot do (browsing files, messages, ...)
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