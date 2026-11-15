import QtQuick
import "../../styles"
import "../network"

// One network in the Wi-Fi list. Tap it to open its actions underneath:
//   connected network   -> Disconnect, Forget
//   saved network       -> Connect, Forget
//   new open network    -> Connect
//   new secured network -> a password field and Connect
Item {
    id: row

    // The control layout block from Island.qml (sizes)
    required property var layout

    // From the list model: one network
    required property string ssid
    required property int level        // signal as 0..3 arcs
    required property bool secured
    required property bool known       // saved before
    required property bool active     // connected right now

    // Is this row open? The list keeps track, so only one row is open at a time.
    property bool expanded: false

    signal toggle()                           // the row was tapped
    signal connectRequested(string password)  // empty for a saved or open network
    signal disconnectRequested()
    signal forgetRequested()

    readonly property bool busy: WifiService.busySsid === ssid
    readonly property bool failed: WifiService.errorSsid === ssid
    readonly property bool needsPassword: secured && !known && !active

    // The small line under the name
    readonly property string statusText: {
        if (busy) return "Connecting…"
        if (failed) return WifiService.errorText
        if (active) return "Connected"
        if (known) return "Saved"
        return secured ? "Secured" : "Open"
    }

    // 0..1, how far the actions have opened
    property real openFade: expanded ? 1 : 0
    Behavior on openFade {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    height: layout.netRowH + openFade * (actions.implicitHeight + layout.netPad)
    clip: true

    // Sends the connect request (a new secured network needs a password first)
    function submit() {
        if (needsPassword && input.text === "") return
        connectRequested(input.text)
        input.text = ""
    }

    // A new secured network asks for its password as soon as it opens; closing clears it
    onExpandedChanged: {
        if (expanded && needsPassword) {
            Qt.callLater(() => input.forceActiveFocus())
        } else {
            input.focus = false
            input.text = ""
        }
    }

    // ── Background: shows on hover and while open ──
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Theme.elevatedBg
        opacity: Math.max(row.openFade, headArea.containsMouse ? 1 : 0)
        Behavior on opacity {
            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }
    }

    // ── The always-visible part: icon, name, status, lock ──
    Item {
        id: head
        width: parent.width
        height: row.layout.netRowH

        // Live signal icon: arcs follow the signal, and pulse while connecting
        WifiIcon {
            x: row.layout.netPad
            anchors.verticalCenter: parent.verticalCenter
            size: row.layout.netIconSize
            color: row.active ? Theme.fg : Theme.fgMuted
            level: row.level
            searching: row.busy
        }

        Column {
            x: row.layout.netPad + row.layout.netIconSize + row.layout.netIconGap
            anchors.verticalCenter: parent.verticalCenter
            width: head.width - x - row.layout.netPad
                - (row.secured ? row.layout.netLockSize + row.layout.netIconGap : 0)

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.ssid
                color: Theme.fg
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeMd
                font.weight: row.active ? Font.DemiBold : Font.Normal
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.statusText
                color: row.failed ? Theme.red : Theme.fgMuted
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeXs
            }
        }

        // Lock on secured networks
        Text {
            anchors.right: parent.right
            anchors.rightMargin: row.layout.netPad
            anchors.verticalCenter: parent.verticalCenter
            visible: row.secured
            text: "lock"
            color: Theme.fgMuted
            font.family: Theme.fontIcon
            font.pixelSize: row.layout.netLockSize
        }

        MouseArea {
            id: headArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggle()
        }
    }

    // ── The actions, under the head ──
    Column {
        id: actions
        x: row.layout.netPad
        y: head.height
        width: row.width - 2 * row.layout.netPad
        spacing: row.layout.netActionGap
        opacity: row.openFade
        visible: row.expanded || row.openFade > 0
        enabled: row.expanded

        // Password, for a new secured network
        Rectangle {
            width: parent.width
            height: row.layout.netActionH
            visible: row.needsPassword
            radius: height / 2
            color: Theme.subBg
            border.width: row.layout.btnBorder
            border.color: input.activeFocus ? Theme.fgMuted : Theme.border

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: row.layout.netPad
                anchors.rightMargin: row.layout.netPad
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                echoMode: TextInput.Password
                color: Theme.fg
                selectionColor: Theme.fgMuted
                selectedTextColor: Theme.bg
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeSm

                Keys.onReturnPressed: row.submit()
                Keys.onEnterPressed: row.submit()
                Keys.onEscapePressed: row.toggle()    // closes this row, not the whole panel
            }

            // Hint while empty
            Text {
                anchors.fill: input
                verticalAlignment: Text.AlignVCenter
                visible: input.text.length === 0
                text: "Password"
                color: Theme.fgMuted
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeSm
            }
        }

        Row {
            spacing: row.layout.netActionGap

            ActionButton {
                layout: row.layout
                text: row.active ? "Disconnect" : "Connect"
                onClicked: row.active ? row.disconnectRequested() : row.submit()
            }

            ActionButton {
                layout: row.layout
                text: "Forget"
                danger: true
                visible: row.known || row.active
                onClicked: row.forgetRequested()
            }
        }
    }

    // A small pill button for the actions
    component ActionButton: Rectangle {
        id: button

        required property var layout
        property string text: ""
        property bool danger: false     // red text, for destructive actions

        signal clicked()

        width: buttonLabel.implicitWidth + 2 * layout.netActionPad
        height: layout.netActionH
        radius: height / 2
        color: Qt.tint(Theme.subBg, Qt.alpha(Theme.border, buttonArea.containsMouse ? 1 : 0))
        border.width: layout.btnBorder
        border.color: Theme.border
        scale: buttonArea.pressed ? Motion.pressScale : 1

        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
        Behavior on scale {
            NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
        }

        Text {
            id: buttonLabel
            anchors.centerIn: parent
            text: button.text
            color: button.danger ? Theme.red : Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeSm
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}