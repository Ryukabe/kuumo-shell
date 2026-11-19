    import QtQuick
import "../styles"
import "../state"

// The caret after typed text: a bar, a block or an underscore. It stays solid while characters
// arrive and blinks once a second while the typing waits (it holds still with reduced motion).
Item {
    id: root

    property string shape: "bar"        // "bar" | "block" | "underscore" | "none"
    property color color: Theme.fg
    // The height of a line of the text, and the width of one character (block and underscore)
    property real lineHeight: 0
    property real charWidth: 0
    // True while the typing waits (before the first character, between lines, at the end)
    property bool waiting: false

    visible: root.shape !== "none"
    width: root.shape === "bar" ? Theme.caretWidth : root.charWidth
    height: root.lineHeight

    // The blink: 1 = shown
    property real blink: 1
    SequentialAnimation on blink {
        running: root.waiting && root.visible && !ShellState.motionReduced
        loops: Animation.Infinite
        NumberAnimation { to: 0; duration: Motion.caretBlinkMs / 2 }
        NumberAnimation { to: 1; duration: Motion.caretBlinkMs / 2 }
    }

    Rectangle {
        // An underscore is a thin line at the bottom; the bar and the block fill the caret
        y: root.shape === "underscore" ? root.height - Theme.caretWidth : 0
        width: root.width
        height: root.shape === "underscore" ? Theme.caretWidth : root.height
        color: root.color
        opacity: root.waiting ? root.blink : 1
    }
}