import QtQuick
import "../styles"
import "../state"
import ".." as Root
import "textUnits.js" as Units

// Types lines out one character at a time behind a caret, like a person at a keyboard. Each
// keystroke waits a slightly different time (the same on every run); the caret stays solid
// while typing and blinks while it waits. With several lines, each is typed, kept for a moment,
// deleted and followed by the next; with `loop` off it stops on the last line, typed out. A
// single line is typed once. A line in a joined script (Bengali, ...) is typed word by word.
// With Config.typewriter off or reduced motion the first line shows whole.
Item {
    id: root

    // The lines to type; one is enough
    property var lines: []
    property bool loop: true
    // "bar" | "block" | "underscore" | "none"
    property string cursor: "bar"
    // Wait before the first character (ms)
    property int delay: 0
    // Typing runs while this is true; turning it on starts again from the first line
    property bool playing: true

    property color color: Theme.fg
    property font font
    font.family: Theme.fontText
    font.pixelSize: Theme.fontSizeMd

    // A single line, or the last line with loop off, has been typed out
    signal completed()

    readonly property bool animated: Root.Config.typewriter && !ShellState.motionReduced

    // ── The state of the typing ──
    property int lineIndex: 0
    // The pieces of the current line, and how many of them are showing
    property var units: []
    property int count: 0
    // "idle" | "start" | "typing" | "pausing" | "deleting" | "done"
    property string phase: "idle"

    readonly property string shown: root.units.slice(0, root.count).join("")
    // The caret blinks while nothing is being typed or deleted
    readonly property bool waiting: root.phase !== "typing" && root.phase !== "deleting"

    function schedule(ms) {
        tick.interval = ms
        tick.restart()
    }

    // How long the next keystroke waits
    function wait(index) {
        return Units.keystrokeWait(Motion.typingSpeed, Motion.typingJitter, root.lineIndex + 1, index)
    }

    function restart() {
        tick.stop()
        root.lineIndex = 0
        root.units = Units.split(root.lines.length > 0 ? root.lines[0] : "")
        root.count = 0
        if (!root.playing || root.lines.length === 0) {
            root.phase = "idle"
        } else if (!root.animated) {
            root.count = root.units.length
            root.phase = "done"
        } else {
            root.phase = "start"
            root.schedule(Math.max(1, root.delay))
        }
    }

    function typeNext() {
        root.count = Math.min(root.count + 1, root.units.length)
        if (root.count < root.units.length) {
            root.schedule(root.wait(root.count))
            return
        }
        // The line is typed out
        const lastLine = root.lineIndex === root.lines.length - 1
        if (root.lines.length === 1 || (lastLine && !root.loop)) {
            root.phase = "done"
            root.completed()
        } else {
            root.phase = "pausing"
            root.schedule(Motion.typingPause)
        }
    }

    function deleteNext() {
        root.count -= 1
        if (root.count > 0) {
            root.schedule(Motion.typingDeleteSpeed)
            return
        }
        // The line is gone: on to the next one
        root.lineIndex = (root.lineIndex + 1) % root.lines.length
        root.units = Units.split(root.lines[root.lineIndex])
        root.phase = "typing"
        root.schedule(root.wait(0))
    }

    function step() {
        if (root.phase === "start") {
            root.phase = "typing"
            root.typeNext()
        } else if (root.phase === "typing") {
            root.typeNext()
        } else if (root.phase === "pausing") {
            root.phase = "deleting"
            root.deleteNext()
        } else if (root.phase === "deleting") {
            root.deleteNext()
        }
    }

    Timer {
        id: tick
        onTriggered: root.step()
    }

    onLinesChanged: root.restart()
    onPlayingChanged: root.restart()
    Component.onCompleted: root.restart()

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