import QtQuick

// Apple-style spring (response + dampingFraction) that chases `target`.
// Interruptible: changing `target` mid-flight keeps the current velocity.
Item {
    id: root
    visible: false
    width: 0
    height: 0

    property real target: 0
    property real value: 0
    property real velocity: 0

    property real response: 0.45         // seconds; lower = snappier
    property real dampingFraction: 0.8   // 1 = no bounce; lower = more bounce
    property bool animated: true

    property real restDelta: 0.05        // settle thresholds
    property real restSpeed: 0.5

    readonly property bool running: frames.running

    // Apple's mapping with mass = 1
    readonly property real _omega: 2 * Math.PI / Math.max(response, 0.01)
    readonly property real _k: _omega * _omega
    readonly property real _c: 2 * dampingFraction * _omega

    function snap() {
        value = target
        velocity = 0
        frames.running = false
    }

    Component.onCompleted: value = target
    onTargetChanged: animated ? frames.running = true : snap()
    onAnimatedChanged: if (!animated) snap()

    FrameAnimation {
        id: frames
        onTriggered: {
            var dt = Math.min(frameTime, 0.05)
            var steps = Math.max(1, Math.ceil(dt / 0.004))
            var h = dt / steps
            var x = root.value
            var v = root.velocity
            for (var i = 0; i < steps; ++i) {
                var a = -root._k * (x - root.target) - root._c * v
                v += a * h
                x += v * h
            }
            root.value = x
            root.velocity = v
            if (Math.abs(x - root.target) < root.restDelta && Math.abs(v) < root.restSpeed)
                root.snap()
        }
    }
}