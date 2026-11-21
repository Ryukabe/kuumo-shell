import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// The polkit prompt: icon, message, user and action on top, then the password field.
// The Authenticate button lives inside the field's right side and grows in once you
// start typing. There is no cancel button: closing the island cancels.
Item {
    id: root

    // layouts.polkit from Island.qml, and how far the content has appeared (0..1)
    property var layout
    property real reveal: 0

    readonly property bool active: IslandState.polkit
    // How far the Authenticate button has grown (0..1)
    readonly property real authFrac: layout.authW > 0
        ? Math.min(1, Math.max(0, authW.value / layout.authW)) : 0

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

    // ── Header ──
    Rectangle {
        id: iconBox
        x: root.layout.padX
        y: root.layout.padTop + (root.layout.headH - height) / 2
        width: root.layout.iconBox
        height: root.layout.iconBox
        radius: Theme.radiusMedium
        color: Theme.elevatedBg

        Text {
            anchors.centerIn: parent
            text: "admin_panel_settings"
            color: Theme.accent
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.iconSize
        }
    }

    Column {
        x: root.layout.padX + root.layout.iconBox + root.layout.iconGap
        y: root.layout.padTop + (root.layout.headH - height) / 2
        width: root.width - x - root.layout.padX
        spacing: root.layout.textGap

        // What is being asked for
        Text {
            width: parent.width
            text: PolkitService.message
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeMd
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // Who authenticates, and the action id
        Text {
            width: parent.width
            text: [PolkitService.userName, PolkitService.actionId].filter(s => s !== "").join("  ·  ")
            color: Theme.fgMuted
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeXs
            elide: Text.ElideRight
        }
    }

    // ── Password field ──
    Rectangle {
        id: box
        x: root.layout.padX
        y: root.layout.padTop + root.layout.headH + root.layout.gap
        width: root.width - 2 * root.layout.padX
        height: root.layout.fieldH
        radius: Theme.radiusMedium
        color: Theme.subBg
        border.width: 1
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
            anchors.leftMargin: root.layout.fieldGap
            anchors.right: authBtn.left
            anchors.rightMargin: root.layout.fieldGap
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
        x: root.layout.padX
        y: box.y + box.height + root.layout.errorGap
        width: root.width - 2 * root.layout.padX
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