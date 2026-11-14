import QtQuick
import QtQuick.Shapes
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

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
    // The moon travels the track, half a moon in from each end
    readonly property real travel: trackW - layout.dotSize

    // The moon follows the level on a slightly bouncy spring
    Spring {
        id: moonSpring
        target: root.layout.dotSize / 2 + OsdService.level * root.travel
        response: Motion.osdFill.response
        dampingFraction: Motion.osdFill.damping
        animated: !ShellState.motionReduced
    }

    Component.onCompleted: moonSpring.snap()

    // The level reached 0 or 100: push the moon past the end so it bounces back
    Connections {
        target: OsdService
        function onEdge(direction) { moonSpring.kick(direction * Motion.osdEdgeKick) }
    }

    // The moon may poke past the ends of the track while it bounces; the fill may not
    readonly property real moonX: moonSpring.value
    readonly property real fillW: Math.max(0, Math.min(trackW, moonX))

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

    // The lit part of the bar
    Rectangle {
        x: root.trackX
        width: root.fillW
        height: track.height
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accent
        opacity: root.lit
    }

    // Moonlight around the leading edge
    Shape {
        id: glow
        readonly property real r: root.layout.glowReach
        x: root.trackX + root.moonX - r
        y: (root.height - 2 * r) / 2
        width: 2 * r
        height: 2 * r
        opacity: root.lit

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.r
                centerY: glow.r
                centerRadius: glow.r
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0;                    color: Qt.alpha(Theme.accent, Theme.glowPeak) }
                GradientStop { position: Theme.glowFalloffAt;  color: Qt.alpha(Theme.accent, Theme.glowPeak * Theme.glowFalloff) }
                GradientStop { position: 1;                    color: Qt.alpha(Theme.accent, 0) }
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
        x: root.trackX + root.moonX - width / 2
        width: root.layout.dotSize
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.accent
        opacity: root.lit
    }
}