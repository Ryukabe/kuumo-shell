import QtQuick
import "../styles"

// A slim scrollbar that floats over the right edge of a Flickable. It is invisible until the
// content scrolls or the pointer comes to the edge, then fades away again. Drag the thumb,
// or click the track to jump. Normally used through MoonFlickable, not on its own.
Item {
    id: root

    required property Flickable flickable

    property int thumbWidth: 6
    property int thumbWidthActive: 10
    // Space between the thumb and the edge (and the ends of the track)
    property int edge: 3
    property int minThumb: 32
    property int hideDelayMs: 900

    readonly property bool pressed: area.pressed
    readonly property bool hovered: area.containsMouse
    readonly property bool scrollable: flickable.contentHeight > flickable.height + 1
    readonly property real range: flickable.contentHeight - flickable.height
    readonly property real trackH: height - 2 * edge
    readonly property real thumbH: flickable.contentHeight > 0
        ? Math.max(minThumb, trackH * Math.min(1, flickable.height / flickable.contentHeight))
        : trackH
    readonly property real progress: range > 0
        ? Math.max(0, Math.min(1, (flickable.contentY - flickable.originY) / range))
        : 0

    // True for a moment after every scroll
    property bool awake: false

    Connections {
        target: root.flickable
        function onContentYChanged() {
            root.awake = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: root.hideDelayMs
        onTriggered: root.awake = false
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.scrollable
        hoverEnabled: true
        preventStealing: true

        // Where inside the thumb it was grabbed
        property real grab: 0

        function moveTo(y) {
            const free = root.trackH - root.thumbH
            if (free <= 0) return
            const p = Math.max(0, Math.min(1, (y - area.grab - root.edge) / free))
            root.flickable.contentY = root.flickable.originY + p * root.range
        }

        onPressed: mouse => {
            root.flickable.cancelFlick()
            const onThumb = mouse.y >= thumb.y && mouse.y <= thumb.y + thumb.height
            area.grab = onThumb ? mouse.y - thumb.y : thumb.height / 2
            area.moveTo(mouse.y)
        }
        onPositionChanged: mouse => {
            if (area.pressed) area.moveTo(mouse.y)
        }
    }

    Rectangle {
        id: thumb

        readonly property bool shown: root.scrollable && (root.awake || root.hovered || root.pressed)

        width: (root.hovered || root.pressed) ? root.thumbWidthActive : root.thumbWidth
        height: root.thumbH
        x: root.width - width - root.edge
        y: root.edge + (root.trackH - root.thumbH) * root.progress
        radius: width / 2
        color: Theme.fgMuted
        opacity: !thumb.shown ? 0 : root.pressed ? 0.8 : root.hovered ? 0.6 : 0.4

        // Quick to appear, slow to go
        Behavior on opacity {
            NumberAnimation { duration: thumb.shown ? 120 : 350; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }
}