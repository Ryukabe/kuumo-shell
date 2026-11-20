import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// The volume / brightness OSD: the icon on the left, then a thin track with a filled stretch.
// The end of the fill follows the level on a bouncy spring. Nothing else: no handle.
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

    readonly property real trackX: layout.iconSize + layout.iconGap
    readonly property real trackW: width - trackX

    // The end of the fill follows the level on a slightly bouncy spring
    Spring {
        id: fillSpring
        target: OsdService.level * root.trackW
        response: Motion.osdFill.response
        dampingFraction: Motion.osdFill.damping
        animated: !ShellState.motionReduced
    }

    Component.onCompleted: fillSpring.snap()

    // The level reached 0 or 100: push the fill's end so it bounces back
    Connections {
        target: OsdService
        function onEdge(direction) { fillSpring.kick(direction * Motion.osdEdgeKick) }
    }

    // The fill may swing past its target while it bounces, but never past the ends of the track
    readonly property real fillW: Math.max(0, Math.min(trackW, fillSpring.value))

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
}