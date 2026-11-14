import QtQuick
import QtQuick.Effects
import "../styles"

// A thin line with a soft glow around it, like the moon in the logo: brightest in
// the middle, fully transparent at both ends. The glow breathes slowly while the
// line is active, and surges when pulse() is called.
Item {
    id: root

    property color color: Theme.fg
    property real thickness: 2      // the sharp core line
    property real spread: 8         // how far the mist reaches past the line
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

    // Alpha profile along the line: 0 at both ends, a soft shoulder, full in the middle
    Gradient {
        id: fade
        orientation: Gradient.Horizontal
        GradientStop { position: 0;                          color: Qt.alpha(root.color, 0) }
        GradientStop { position: Theme.glowShoulderAt;       color: Qt.alpha(root.color, Theme.glowShoulder) }
        GradientStop { position: 0.5;                        color: root.color }
        GradientStop { position: 1 - Theme.glowShoulderAt;   color: Qt.alpha(root.color, Theme.glowShoulder) }
        GradientStop { position: 1;                          color: Qt.alpha(root.color, 0) }
    }

    // Source for the mist: a band a little taller than the line, blurred below
    Rectangle {
        id: band
        visible: false
        layer.enabled: true
        width: root.width
        height: root.thickness + root.spread
        gradient: fade
    }

    MultiEffect {
        y: (root.height - height) / 2
        width: band.width
        height: band.height
        source: band
        blurEnabled: true
        blurMax: Math.max(1, Math.round(root.spread))
        blur: 1.0
        opacity: root.level
    }

    // The sharp core line on top of the mist
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