import QtQuick
import QtQuick.Shapes
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// A slider drawn like the OSD: icon on the left, a track with a moon on it, a value on the right.
// It only shows a level and reports where the user dragged, tapped or stepped; it never sets
// anything itself.
// While you move it (pointer or keyboard) the moon sits exactly where you put it, with no spring,
// so it is easy to place, and it stays there for a moment after you let go. The bounce is kept for
// changes that come from elsewhere (the volume keys, other apps).
// Click it (or Tab to it) and the keyboard works: arrows step, Page Up/Down and Shift+arrows take
// big steps, Home and End jump to the ends.
Item {
    id: row

    // The control layout block from Island.qml (sizes)
    required property var layout
    // Icon ligature name, e.g. "volume_up"
    required property string iconName
    // The real level from the service, 0..1
    required property real level
    // False turns the bar's light off (e.g. muted)
    property bool lit: true
    // True makes the icon tappable (e.g. to mute)
    property bool iconTappable: false
    // The text on the right; empty shows the level as a percentage
    property string valueText: ""
    // True draws the whole track as a color sweep (e.g. warm to cold) instead of a fill
    property bool gradientTrack: false
    property color startColor: Theme.yellow
    property color endColor: Theme.blue
    // Keyboard steps, as a share of the whole range
    property real step: Root.Config.sliderStep
    property real largeStep: Root.Config.sliderLargeStep

    // The user dragged to a new level (0..1)
    signal moved(real value)
    // The user tapped the icon
    signal iconClicked()

    height: layout.rowH
    activeFocusOnTab: true

    // ── Following the user ──
    // While the pointer is down, and for sliderHoldMs after you let go or step with a key, the
    // moon shows the level you set. After that it follows the real level, so changes made
    // elsewhere show up too (with the bounce).
    readonly property bool dragging: pointer.pressed
    property bool holding: false
    readonly property bool following: dragging || holding
    property real dragLevel: 0
    readonly property real shownLevel: following ? dragLevel : level

    Timer {
        id: settle
        interval: Motion.sliderHoldMs
        onTriggered: row.holding = false
    }

    // Which way the last change went (1 up, -1 down); the icon rolls that way
    property int iconDirection: 1

    // True after a key press, so the focus ring shows for the keyboard only
    property bool keyboardMode: false

    // ── Geometry ──
    readonly property real trackX: layout.iconSize + layout.iconGap
    readonly property real trackW: width - trackX - layout.pctGap - layout.pctW
    // The moon travels the track, half a moon in from each end
    readonly property real travel: trackW - layout.dotSize
    readonly property real moonX: moonSpring.value
    // The moon may poke past the ends of the track while it bounces; the fill may not
    readonly property real fillW: Math.max(0, Math.min(trackW, moonX))

    // The bar's light, fading out while `lit` is false
    property real litFade: lit ? 1 : 0
    Behavior on litFade {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    // The moon follows the level on the same spring as the OSD. While you move it, it is not
    // animated, so it stays exactly under the pointer.
    Spring {
        id: moonSpring
        target: row.layout.dotSize / 2 + row.shownLevel * row.travel
        response: Motion.osdFill.response
        dampingFraction: Motion.osdFill.damping
        animated: !ShellState.motionReduced && !row.following
    }

    Component.onCompleted: moonSpring.snap()

    // Puts the level where the user chose and reports it
    function setLevel(value) {
        row.iconDirection = value >= row.shownLevel ? 1 : -1
        row.dragLevel = value
        row.holding = true
        settle.restart()
        moonSpring.snap()
        row.moved(value)
    }

    // The color sweep for a gradient track
    Gradient {
        id: sweep
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: row.startColor }
        GradientStop { position: 1; color: row.endColor }
    }

    // ── Parts, left to right ──
    IconSwap {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        name: row.iconName
        color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, row.litFade))
        pixelSize: row.layout.iconSize
        slide: row.layout.iconSize / 2
        direction: row.iconDirection
        animated: !ShellState.motionReduced
    }

    // The track
    Rectangle {
        id: track
        x: row.trackX
        width: row.trackW
        height: row.layout.barH
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.border
        gradient: row.gradientTrack ? sweep : null
    }

    // The lit part of the bar (not used for a gradient track)
    Rectangle {
        x: row.trackX
        width: row.fillW
        height: track.height
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accent
        opacity: row.gradientTrack ? 0 : row.litFade
    }

    // Moonlight around the leading edge
    Shape {
        id: glow
        readonly property real r: row.layout.glowReach
        x: row.trackX + row.moonX - r
        y: (row.height - 2 * r) / 2
        width: 2 * r
        height: 2 * r
        opacity: row.litFade

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.r
                centerY: glow.r
                centerRadius: glow.r
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0;                   color: Qt.alpha(Theme.accent, Theme.glowPeak) }
                GradientStop { position: Theme.glowFalloffAt; color: Qt.alpha(Theme.accent, Theme.glowPeak * Theme.glowFalloff) }
                GradientStop { position: 1;                   color: Qt.alpha(Theme.accent, 0) }
            }
            startX: 0; startY: 0
            PathLine { x: glow.width; y: 0 }
            PathLine { x: glow.width; y: glow.height }
            PathLine { x: 0; y: glow.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // The moon itself
    Rectangle {
        x: row.trackX + row.moonX - width / 2
        width: row.layout.dotSize
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accent
        opacity: row.litFade
    }

    // A thin ring around the moon while the keyboard is in use
    Rectangle {
        x: row.trackX + row.moonX - width / 2
        width: row.layout.dotSize * 2
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        border.width: row.layout.btnBorder
        border.color: Theme.accent
        opacity: row.activeFocus && row.keyboardMode ? 0.6 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }
    }

    // The value on the right
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: row.layout.pctW
        horizontalAlignment: Text.AlignRight
        text: row.valueText !== "" ? row.valueText : Math.round(row.shownLevel * 100) + "%"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }

    // ── Keyboard ──
    // Arrows step, Page Up/Down and Shift+arrows take the large step, Home and End jump to the ends
    Keys.onPressed: event => {
        const big = (event.modifiers & Qt.ShiftModifier)
            || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown
        const amount = big ? row.largeStep : row.step
        let value = null

        if (event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_PageUp)
            value = row.shownLevel + amount
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Down || event.key === Qt.Key_PageDown)
            value = row.shownLevel - amount
        else if (event.key === Qt.Key_Home)
            value = 0
        else if (event.key === Qt.Key_End)
            value = 1

        if (value === null) return
        row.keyboardMode = true
        row.setLevel(Math.max(0, Math.min(1, value)))
        event.accepted = true
    }

    // ── Pointer ──
    // Tap the icon (only when `iconTappable`)
    MouseArea {
        x: 0
        width: row.trackX
        height: row.height
        enabled: row.iconTappable
        cursorShape: row.iconTappable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            row.iconDirection = row.lit ? -1 : 1    // muting rolls the icon down, unmuting up
            row.iconClicked()
        }
    }

    // Press or drag anywhere on the track row to set the level
    MouseArea {
        id: pointer
        x: row.trackX
        width: row.trackW
        height: row.height
        cursorShape: Qt.PointingHandCursor

        // Turns the pointer position into a level and reports it
        function updateFromPointer() {
            const value = Math.max(0, Math.min(1, (mouseX - row.layout.dotSize / 2) / row.travel))
            row.setLevel(value)
        }

        onPressed: {
            row.keyboardMode = false
            row.forceActiveFocus()
            settle.stop()
            row.dragLevel = row.level   // start from the real level, so the direction is right
            row.holding = true
            updateFromPointer()
        }
        onPositionChanged: if (pressed) updateFromPointer()
        onReleased: settle.restart()
        onCanceled: settle.restart()
    }
}