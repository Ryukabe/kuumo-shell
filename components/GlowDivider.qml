import QtQuick
import QtQuick.Shapes
import "../styles"

// A thin line with a soft mist above it, like the moon in the logo. The core line is
// brightest in the middle and transparent at both ends. The mist is one-sided: a
// half-ellipse sitting on the line, strongest at the line and fading upward and
// outward. It breathes slowly while active, and surges when pulse() is called.
Item {
    id: root

    property color color: Theme.fg
    property real thickness: 2      // the sharp core line
    property real reach: 12         // how high the mist rises above the line
    property bool active: true      // false stops all motion
    property bool animated: true
    property bool breathes: true
    property bool surges: true

    property real breath: 0         // 0..1, loops while active
    property real surge: 0          // 1 right after pulse(), then decays to 0

    readonly property real level: Math.min(1,
        Theme.glowRest + Theme.glowBreathe * breath + Theme.glowSurge * surge)

    implicitHeight: thickness

    function pulse() {
        if (surges && animated && active) surgeAnim.restart()
    }

    // Alpha along the core line: 0 at both ends, a soft shoulder, full in the middle
    Gradient {
        id: fade
        orientation: Gradient.Horizontal
        GradientStop { position: 0;                          color: Qt.alpha(root.color, 0) }
        GradientStop { position: Theme.glowShoulderAt;       color: Qt.alpha(root.color, Theme.glowShoulder) }
        GradientStop { position: 0.5;                        color: root.color }
        GradientStop { position: 1 - Theme.glowShoulderAt;   color: Qt.alpha(root.color, Theme.glowShoulder) }
        GradientStop { position: 1;                          color: Qt.alpha(root.color, 0) }
    }

    // The mist: drawn as a half circle as wide as the line, then squashed to `reach`
    // tall, so it becomes a half-ellipse resting on the line.
    Shape {
        id: mist
        width: root.width
        height: root.width / 2
        y: -height
        opacity: root.level
        transform: Scale {
            origin.y: mist.height
            yScale: root.reach / Math.max(1, mist.height)
        }

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: mist.width / 2
                centerY: mist.height
                centerRadius: mist.width / 2
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0;                      color: Qt.alpha(root.color, Theme.glowPeak) }
                GradientStop { position: Theme.glowFalloffAt;    color: Qt.alpha(root.color, Theme.glowPeak * Theme.glowFalloff) }
                GradientStop { position: 1;                      color: Qt.alpha(root.color, 0) }
            }
            startX: 0; startY: 0
            PathLine { x: mist.width; y: 0 }
            PathLine { x: mist.width; y: mist.height }
            PathLine { x: 0; y: mist.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // The sharp core line
    Rectangle {
        y: (root.height - height) / 2
        width: root.width
        height: root.thickness
        radius: height / 2
        gradient: fade
        opacity: root.level
    }

    SequentialAnimation {
        running: root.active && root.animated && root.breathes
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "breath"; to: 1; duration: Motion.breatheMs / 2; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "breath"; to: 0; duration: Motion.breatheMs / 2; easing.type: Easing.InOutSine }
    }

    NumberAnimation {
        id: surgeAnim
        target: root
        property: "surge"
        from: 1
        to: 0
        duration: Motion.surgeMs
        easing.type: Easing.OutCubic
    }
}