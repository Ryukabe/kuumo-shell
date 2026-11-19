import QtQuick
import "../styles"
import "../state"
import ".." as Root
import "textUnits.js" as Units

// A line that corrects itself. It is typed out the first time. When `text` changes it deletes
// only as far back as the old and the new line share, then types the rest ("Search apps" to
// "Search wallpapers" removes just "apps"). Typing waits like TypingText, deleting is a little
// faster. A line in a joined script (Bengali, ...) is edited word by word. With Config.typewriter
// off or reduced motion the new line replaces the old at once.
Item {
    id: root

    // The line to show
    property string text: ""
    // "bar" | "block" | "underscore" | "none"
    property string cursor: "bar"
    // Wait before the first character (ms)
    property int delay: 0
    property bool playing: true

    property color color: Theme.fg
    property font font
    font.family: Theme.fontText
    font.pixelSize: Theme.fontSizeMd

    // The line showing is the line asked for
    signal completed()

    readonly property bool animated: Root.Config.typewriter && !ShellState.motionReduced

    // The pieces of `text`, the pieces showing, and where the editing is
    property var target: []
    property var current: []
    // "idle" | "start" | "deleting" | "typing" | "done"
    property string phase: "idle"

    readonly property string shown: root.current.join("")
    readonly property bool waiting: root.phase === "idle" || root.phase === "start" || root.phase === "done"

    function schedule(ms) {
        tick.interval = ms
        tick.restart()
    }

    function wait() {
        return Units.keystrokeWait(Motion.typingSpeed, Motion.typingJitter, 1, root.current.length)
    }

    // Decides what comes next: delete back to what the two lines share, type on, or finish
    function go() {
        const keep = Units.sharedStart(root.current, root.target)
        if (root.current.length > keep) {
            root.phase = "deleting"
            root.schedule(Motion.backspaceSpeed)
        } else if (root.current.length < root.target.length) {
            root.phase = "typing"
            root.schedule(root.wait())
        } else {
            root.phase = "done"
            root.completed()
        }
    }

    function retarget() {
        tick.stop()
        root.target = Units.split(root.text)
        if (!root.playing) {
            root.current = []
            root.phase = "idle"
        } else if (!root.animated) {
            root.current = root.target
            root.phase = "done"
        } else if (root.current.length === 0) {
            root.phase = "start"
            root.schedule(Math.max(1, root.delay))
        } else {
            root.go()
        }
    }

    function step() {
        if (root.phase === "start") {
            root.go()
        } else if (root.phase === "deleting") {
            root.current = root.current.slice(0, root.current.length - 1)
            root.go()
        } else if (root.phase === "typing") {
            root.current = root.current.concat([root.target[root.current.length]])
            root.go()
        }
    }

    Timer {
        id: tick
        onTriggered: root.step()
    }

    onTextChanged: root.retarget()
    onPlayingChanged: root.retarget()
    Component.onCompleted: root.retarget()

    // ── What it looks like ──
    TextMetrics {
        id: metrics
        font: root.font
        text: "M"
    }

    implicitWidth: label.implicitWidth + (caret.visible ? caret.width : 0)
    implicitHeight: metrics.height

    Text {
        id: label
        height: root.height
        verticalAlignment: Text.AlignVCenter
        text: root.shown
        color: root.color
        font: root.font
    }

    TypeCaret {
        id: caret
        x: label.implicitWidth
        y: (root.height - height) / 2
        shape: root.animated ? root.cursor : "none"
        color: root.color
        lineHeight: metrics.height
        charWidth: metrics.advanceWidth
        waiting: root.waiting
    }
}