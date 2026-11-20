import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// The volume / brightness OSD: icon on the left, then a thin track with a filled stretch and a
// round thumb. The thumb follows the level on a bouncy spring, and gets a push when the level
// reaches 0 or 100.
Item {
    id: root

    // The osd layout block from Island.qml
    required property var layout
    // 0..1, how far the OSD content has appeared (from Island.qml)
    required property real reveal

    width: layout.w - 2 * layout.padX
    height: layout.iconSize
    opacity: reveal
    enabled: false

    // The bar's light: fades out while the volume is muted
    property real lit: OsdService.lit ? 1 : 0
    Behavior on lit {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    // The thumb is twice the size of the layout's dot, so it reads as a handle
    readonly property real thumbSize: layout.dotSize * 2
    readonly property real trackX: layout.iconSize + layout.iconGap
    readonly property real trackW: width - trackX
    // The thumb travels the track, half a thumb in from each end
    readonly property real travel: trackW - thumbSize

    // The thumb follows the level on a slightly bouncy spring
    Spring {
        id: thumbSpring
        target: root.thumbSize / 2 + OsdService.level * root.travel
        response: Motion.osdFill.response
        dampingFraction: Motion.osdFill.damping
        animated: !ShellState.motionReduced
    }

    Component.onCompleted: thumbSpring.snap()

    // The level reached 0 or 100: push the thumb past the end so it bounces back
    Connections {
        target: OsdService
        function onEdge(direction) { thumbSpring.kick(direction * Motion.osdEdgeKick) }
    }

    // The thumb may poke past the ends of the track while it bounces; the fill may not
    readonly property real thumbX: thumbSpring.value
    readonly property real fillW: Math.max(0, Math.min(trackW, thumbX))

    IconSwap {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        name: OsdService.iconName
        color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, root.lit))
        pixelSize: root.layout.iconSize
        slide: root.layout.iconSize / 2
        direction: OsdService.iconDirection
        animated: !ShellState.motionReduced
    }

    // The track
    Rectangle {
        id: track
        x: root.trackX
        width: root.trackW
        height: root.layout.barH
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.border
    }

    // The filled stretch of the bar
    Rectangle {
        x: root.trackX
        width: root.fillW
        height: track.height
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accent
        opacity: root.lit
    }

    // The thumb: a round handle with a ring
    Rectangle {
        x: root.trackX + root.thumbX - width / 2
        width: root.thumbSize
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        border.width: root.layout.barH / 2
        border.color: Theme.accent
        opacity: root.lit
    }
}