import QtQuick
import "../styles"
import "../state"
import ".." as Root

// A text field with a typewriter feel. The placeholder types itself out when `playing` turns on
// (or the placeholder changes), and every character you type fades in and rises into place.
// Underneath is a normal TextInput that keeps the keyboard, the cursor and the selection; its
// own letters are made clear and the typed characters are drawn on top, one by one.
// Config.typewriter turns the effect off. The field draws its own text instead (no per-character
// animation) while an input method is composing and when the text has letters outside Latin
// (Bengali, emoji, ...), because single characters would break their shapes.
FocusScope {
    id: root

    // The hint shown while the field is empty
    property string placeholder: ""
    property int pixelSize: Theme.fontSizeMd
    property int echoMode: TextInput.Normal
    // The placeholder types itself out while this is true
    property bool playing: true

    property alias text: field.text
    // The TextInput itself, for the cursor position and selection
    property alias input: field

    // Every key press is passed on here; set event.accepted when you handle it
    signal keyPressed(var event)

    implicitHeight: field.implicitHeight

    function forceFieldFocus() { field.forceActiveFocus() }

    // Whether the typed characters are drawn one by one
    readonly property bool drawn: Root.Config.typewriter && !ShellState.motionReduced
        && !field.inputMethodComposing && !/[^\u0000-\u024F]/.test(field.displayText)

    TextInput {
        id: field
        anchors.fill: parent
        focus: true
        verticalAlignment: TextInput.AlignVCenter
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
        echoMode: root.echoMode
        clip: true
        selectByMouse: true

        // The letters are drawn by the overlay below; the field keeps cursor and selection
        color: root.drawn ? "transparent" : Theme.fg
        selectionColor: Theme.elevatedBg
        selectedTextColor: root.drawn ? "transparent" : Theme.fg
        cursorDelegate: Rectangle {
            width: Theme.caretWidth
            color: Theme.fg
        }

        Keys.onPressed: event => root.keyPressed(event)
    }

    // The typed characters, one Text each, where the field's own letters would be
    Item {
        anchors.fill: parent
        clip: true
        visible: root.drawn

        Repeater {
            model: root.drawn ? field.displayText.length : 0

            Text {
                id: letter
                required property int index

                // positionToRectangle is a function call, so the text is read to refresh the position
                x: { field.displayText; return field.positionToRectangle(index).x }
                y: (parent.height - height) / 2
                text: field.displayText.charAt(index)
                color: Theme.fg
                font: field.font
                opacity: 0
                transform: Translate { id: rise; y: Motion.typedCharRise }

                // Settles in when the character appears
                Component.onCompleted: settle.start()
                ParallelAnimation {
                    id: settle
                    NumberAnimation {
                        target: letter; property: "opacity"; to: 1
                        duration: Motion.typedCharMs; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: rise; property: "y"; to: 0
                        duration: Motion.typedCharMs; easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // ── The placeholder, typed out one character at a time ──
    property int typed: 0

    Text {
        anchors.fill: field
        verticalAlignment: Text.AlignVCenter
        visible: field.text === ""
        text: root.placeholder.slice(0, root.typed)
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
        elide: Text.ElideRight
    }

    NumberAnimation {
        id: typeOut
        target: root
        property: "typed"
        from: 0
    }

    // Starts the typing again; shows the whole hint at once when the effect is off
    function retype() {
        typeOut.stop()
        const total = root.placeholder.length
        if (!root.playing) {
            root.typed = 0
            return
        }
        if (!Root.Config.typewriter || ShellState.motionReduced) {
            root.typed = total
            return
        }
        root.typed = 0
        typeOut.to = total
        typeOut.duration = total * Motion.typeMs
        typeOut.start()
    }

    onPlaceholderChanged: retype()
    onPlayingChanged: retype()
    Component.onCompleted: retype()
}