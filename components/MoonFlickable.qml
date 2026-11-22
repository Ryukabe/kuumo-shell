import QtQuick

// A scrolling area in the moon style: smooth wheel scrolling, a rubber-band bounce at the
// top and bottom, and a floating scrollbar that hides when idle. Use it like a Flickable:
// put the content inside it and set contentHeight.
Item {
    id: root

    default property alias content: flick.flickableData
    property alias contentHeight: flick.contentHeight
    property alias flickable: flick

    // How the scrolling feels
    property real wheelStep: 90            // px per notch of a mouse wheel
    property int glideMs: 300              // how long one notch glides
    property real bounce: 40               // most the content is pulled past an end, in px
    property int pullMs: 150               // time to be pulled past the end
    property int settleMs: 500             // time to come back
    property int settleEasing: Easing.OutCubic   // Easing.OutBack gives a springier return

    // Where the wheel is heading, kept inside the ends
    property real aim: 0
    property bool pulled: false

    function stopGlide() {
        glide.stop()
        settle.stop()
        root.pulled = false
    }

    // Scroll by dy pixels with an animation. Returns false when there is nothing to scroll.
    function scrollBy(dy, smooth) {
        const minY = flick.originY
        const maxY = flick.originY + flick.contentHeight - flick.height
        if (maxY <= minY) return false

        settle.stop()
        flick.cancelFlick()
        const start = glide.running ? root.aim : flick.contentY
        const raw = start + dy
        const inside = Math.max(minY, Math.min(maxY, raw))
        const over = raw - inside          // how far the wheel asked to go past an end

        root.aim = inside
        root.pulled = over !== 0
        glide.to = over !== 0
            ? inside + Math.sign(over) * Math.min(root.bounce, Math.abs(over) * 0.5)
            : inside
        glide.duration = over !== 0 ? root.pullMs : (smooth ? root.glideMs : 90)
        glide.restart()
        return true
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds
        contentWidth: width

        // Dragging (touch) takes over from a running glide
        onDraggingChanged: if (dragging) root.stopGlide()
    }

    // Catches the wheel only; clicks and drags go through to what is underneath
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const px = wheel.pixelDelta.y
            wheel.accepted = px !== 0
                ? root.scrollBy(-px, false)
                : root.scrollBy(-wheel.angleDelta.y / 120 * root.wheelStep, true)
        }
    }

    NumberAnimation {
        id: glide
        target: flick
        property: "contentY"
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.pulled) {
                root.pulled = false
                settle.to = root.aim
                settle.restart()
            }
        }
    }

    NumberAnimation {
        id: settle
        target: flick
        property: "contentY"
        duration: root.settleMs
        easing.type: root.settleEasing
    }

    MoonScrollBar {
        id: bar
        flickable: flick
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 14

        // Grabbing the scrollbar stops any wheel glide
        onPressedChanged: if (pressed) root.stopGlide()
    }
}