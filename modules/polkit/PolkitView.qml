import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// The polkit prompt, top to bottom:
//  - header row: a round icon and the title on the left, the user (a pill) in the corner
//  - the message, on its own full-width lines
//  - the password field, with the Authenticate button inside its right side (it grows in
//    once you type)
//  - a line for a wrong password
// There is no cancel button: closing the island cancels.
Item {
    id: root

    // layouts.polkit from Island.qml, and how far the content has appeared (0..1)
    property var layout
    property real reveal: 0

    readonly property bool active: IslandState.polkit
    // How far the Authenticate button has grown (0..1)
    readonly property real authFrac: layout.authW > 0
        ? Math.min(1, Math.max(0, authW.value / layout.authW)) : 0

    // Y positions of the blocks, top to bottom, all from the layout block
    readonly property real msgY: layout.padTop + layout.headH + layout.msgGap
    readonly property real fieldY: msgY + layout.msgH + layout.fieldGap

    opacity: reveal
    visible: reveal > 0

    function submit() {
        if (field.text.length > 0) PolkitService.submit(field.text)
    }

    // The keyboard goes to the field as soon as the island opens
    onActiveChanged: {
        if (active) {
            CapsLockService.refresh()
            field.forceActiveFocus()
        } else {
            field.text = ""
            field.revealed = false
        }
    }
    onVisibleChanged: if (visible && active) field.forceActiveFocus()

    // The button grows with a spring when the first character is typed
    Spring {
        id: authW
        target: field.text.length > 0 ? root.layout.authW : 0
        response: Motion.authButton.response
        dampingFraction: Motion.authButton.damping
        animated: !ShellState.motionReduced
    }

    // The field shakes after a wrong password: a spring around its place, kicked sideways
    Spring {
        id: shake
        target: 0
        response: Motion.shake.response
        dampingFraction: Motion.shake.damping
        animated: !ShellState.motionReduced && Root.Config.polkitShake
    }

    Connections {
        target: PolkitService
        function onWrongPassword() {
            field.text = ""
            field.forceActiveFocus()
            if (shake.animated) shake.kick(Motion.shakeKick)
        }
    }

    // ── Header row ──
    // Round icon with a thin ring, like the power menu's buttons
    Rectangle {
        id: iconRing
        x: root.layout.padX
        y: root.layout.padTop + (root.layout.headH - height) / 2
        width: root.layout.headH
        height: root.layout.headH
        radius: Theme.radiusFull
        color: Theme.subBg
        border.width: root.layout.ringW
        border.color: Theme.border

        Text {
            anchors.centerIn: parent
            text: "admin_panel_settings"
            color: Theme.accent
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.iconSize
        }
    }

    // Title: takes the room left between the icon and the user pill
    Text {
        x: iconRing.x + iconRing.width + root.layout.iconGap
        y: root.layout.padTop + (root.layout.headH - height) / 2
        width: userPill.x - x - root.layout.iconGap
        text: "Authentication required"
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeMd
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    // The user: a pill in the top right corner
    Rectangle {
        id: userPill
        visible: PolkitService.userName !== ""
        x: root.width - root.layout.padX - width
        y: root.layout.padTop + (root.layout.headH - height) / 2
        width: pillRow.implicitWidth + 2 * root.layout.pillPad
        height: root.layout.pillH
        radius: Theme.radiusFull
        color: Theme.elevatedBg
        border.width: root.layout.ringW
        border.color: Theme.border

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: root.layout.pillGap

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "person"
                color: Theme.accent
                font.family: Theme.fontIcon
                font.pixelSize: root.layout.pillIconSize
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: PolkitService.userName
                color: Theme.fg
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.DemiBold
            }
        }
    }

    // ── Message ──
    Text {
        x: root.layout.padX
        y: root.msgY
        width: root.width - 2 * root.layout.padX
        height: root.layout.msgH
        text: PolkitService.message
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeMd
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        verticalAlignment: Text.AlignTop
    }

    // ── Password field ──
    Rectangle {
        id: box
        x: root.layout.padX
        y: root.fieldY
        width: root.width - 2 * root.layout.padX
        height: root.layout.fieldH
        radius: Theme.radiusMedium
        color: Theme.subBg
        border.width: root.layout.ringW
        border.color: field.activeFocus ? Theme.accent : Theme.border
        transform: Translate { x: shake.value }

        Behavior on border.color {
            ColorAnimation { duration: Motion.hoverFade }
        }

        // A lock; turns into the caps lock symbol while caps lock is on
        Text {
            id: lead
            x: root.layout.fieldPad
            anchors.verticalCenter: parent.verticalCenter
            text: CapsLockService.on ? "keyboard_capslock" : "lock"
            color: CapsLockService.on ? Theme.yellow : Theme.fgMuted
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.capsSize
        }

        PasswordField {
            id: field
            anchors.left: lead.right
            anchors.leftMargin: root.layout.innerGap
            anchors.right: authBtn.left
            anchors.rightMargin: root.layout.innerGap
            height: parent.height
            font.pixelSize: Theme.fontSizeMd
            placeholder: "Password"
            playing: root.active

            onAccepted: root.submit()
            onEscaped: IslandState.closeAll()
            onKeyPressed: event => {
                if (event.key === Qt.Key_CapsLock) CapsLockService.refresh()
            }
            // Typing again clears the "wrong password" line
            onTextChanged: if (text !== "") PolkitService.clearError()
        }

        // Authenticate: hidden until you type, then grows in from the right edge
        Rectangle {
            id: authBtn
            anchors.right: parent.right
            anchors.rightMargin: root.layout.btnInset
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, authW.value)
            height: box.height - 2 * root.layout.btnInset
            radius: Math.max(0, box.radius - root.layout.btnInset)
            color: Theme.accent
            opacity: root.authFrac
            clip: true
            visible: width > 0.5

            scale: authMouse.pressed ? Motion.pressScale : 1
            Behavior on scale {
                NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.centerIn: parent
                text: "arrow_forward"
                color: Theme.bg
                font.family: Theme.fontIcon
                font.pixelSize: root.layout.btnIconSize
            }

            MouseArea {
                id: authMouse
                anchors.fill: parent
                enabled: root.authFrac > 0.5
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submit()
            }
        }
    }

    // ── Wrong password ──
    Text {
        x: root.layout.padX + root.layout.fieldPad
        y: box.y + box.height + root.layout.errorGap
        width: root.width - 2 * root.layout.padX - root.layout.fieldPad
        text: "Wrong password, try again"
        color: Theme.red
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
        opacity: PolkitService.wrong ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: PolkitService.wrong ? Motion.fadeIn : Motion.fadeOut
                easing.type: Easing.OutCubic
            }
        }
    }
}