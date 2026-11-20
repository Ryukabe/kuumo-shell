import QtQuick
import "../styles"
import "../state"

// A password field. What you type shows as dots. The eye turns the dots into the characters one
// after another (each dot shrinks as its character grows in) and back into dots at once. The hint
// types itself out (BackspaceText). Underneath is a normal TextInput that keeps the keyboard, the
// cursor and the selection; its own glyphs are made clear and the cells above are drawn at the
// positions of its characters. A password with letters outside Latin (Bengali, ...) is revealed
// with the field's own text, without the turn animation.
FocusScope {
    id: root

    property string placeholder: "Password"
    // The hint types itself out while this is true
    property bool playing: true
    property bool revealed: false

    property color color: Theme.fg
    property font font
    font.family: Theme.fontMono
    font.pixelSize: Theme.fontSizeSm

    property alias text: field.text

    // Enter, Esc, and every key press (set event.accepted when you handle it)
    signal accepted()
    signal escaped()
    signal keyPressed(var event)

    readonly property bool animated: !ShellState.motionReduced
    // Complex scripts are revealed with the field's own text
    readonly property bool plainReveal: root.revealed && /[^\u0000-\u024F]/.test(field.text)

    TextInput {
        id: field
        anchors.left: parent.left
        anchors.right: eye.left
        anchors.rightMargin: Theme.spacingSm
        height: parent.height
        focus: true
        verticalAlignment: TextInput.AlignVCenter
        font: root.font
        echoMode: root.plainReveal ? TextInput.Normal : TextInput.Password
        clip: true
        selectByMouse: true

        // The characters are drawn by the cells below; the field keeps cursor and selection
        color: root.plainReveal ? root.color : "transparent"
        selectionColor: Theme.elevatedBg
        selectedTextColor: root.plainReveal ? root.color : "transparent"
        cursorDelegate: Rectangle {
            width: Theme.caretWidth
            color: Theme.fg
            opacity: field.text === "" ? 0 : 1
        }

        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: root.escaped()
        Keys.onPressed: event => root.keyPressed(event)
    }

    // One cell per character, at the character's place in the field: a dot, turning into the character
    Item {
        anchors.fill: field
        clip: true
        visible: !root.plainReveal

        Repeater {
            model: field.text.length

            Item {
                id: cell
                required property int index

                // positionToRectangle is a function call, so the text is read to refresh the values
                readonly property real edgeLeft: { field.text; return field.positionToRectangle(index).x }
                readonly property real edgeRight: { field.text; return field.positionToRectangle(index + 1).x }
                readonly property string ch: field.text.charAt(index)

                // 0 = a dot, 1 = the character
                property real turn: 0

                x: cell.edgeLeft
                width: cell.edgeRight - cell.edgeLeft
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: field.passwordCharacter
                    color: root.color
                    font: root.font
                    scale: 1 - cell.turn
                    opacity: 1 - cell.turn
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.ch
                    color: root.color
                    font: root.font
                    scale: cell.turn
                    opacity: cell.turn
                }

                SequentialAnimation {
                    id: show
                    PauseAnimation { duration: cell.index * Motion.passwordStagger }
                    NumberAnimation {
                        target: cell
                        property: "turn"
                        to: 1
                        duration: Motion.passwordMs
                        easing.type: Easing.OutCubic
                    }
                }

                Component.onCompleted: cell.turn = root.revealed ? 1 : 0

                Connections {
                    target: root
                    function onRevealedChanged() {
                        show.stop()
                        if (root.revealed && root.animated) show.start()
                        else cell.turn = root.revealed ? 1 : 0
                    }
                }
            }
        }
    }

    // The hint, typed out
    BackspaceText {
        y: (root.height - height) / 2
        height: implicitHeight
        visible: field.text === ""
        playing: root.playing
        text: root.placeholder
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: root.font.pixelSize
    }

    // The eye
    Text {
        id: eye
        anchors.right: parent.right
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: root.revealed ? "visibility_off" : "visibility"
        color: Theme.fgMuted
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.revealed = !root.revealed
        }
    }
}