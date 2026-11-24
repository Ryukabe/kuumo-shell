import QtQuick
import QtQuick.Shapes
import "../.." as Root
import "../../styles"
import "../../state"

// A phone with a battery ring just inside the edge of the circle around it (the moon of the
// control center button, or the card of the KDE Connect page). Give it the size of that
// circle. The ring fills with the battery level, turns red when the battery is low, and
// breathes while the phone charges. A bolt shows on the phone's screen while it charges,
// the whole icon dims and a crossed-out phone shows while the phone is offline, and two
// waves ripple out of the phone after an action (ping, find my phone, ...).
Item {
    id: root

    property int size: Theme.fontSizeLg
    property color color: Theme.fg
    property real level: 0           // battery, 0..1
    property bool active: false      // the phone is reachable
    property bool charging: false
    // The ring. The button follows a setting; the KDE Connect page always shows it.
    property bool ringEnabled: Root.Config.kdeConnectBatteryRing

    width: size
    height: size

    // ── Drawing proportions ──
    readonly property real strokeRatio: 0.07    // ring thickness, as a fraction of `size`
    readonly property real insetRatio: 0       // gap between the ring and the edge of the circle
    readonly property real phoneRatio: 0.5      // phone symbol size, as a fraction of `size`
    readonly property real boltRatio: 0.2       // bolt size, as a fraction of `size`
    readonly property real fullTurn: 359.9      // a full circle is drawn as just under 360 degrees
    readonly property int smoothSamples: 4      // edge smoothing

    readonly property real stroke: size * strokeRatio
    readonly property real ringRadius: size / 2 - size * insetRatio - stroke / 2

    // The battery is at or under the level chosen in Settings (and not charging)
    readonly property bool low: active && !charging && level > 0
        && level * 100 <= Root.Config.kdeConnectLowBattery
    readonly property color ringColor: low ? Theme.red : color

    // How much of the ring is filled (0..1), eased
    property real filled: active ? level : 0
    Behavior on filled {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    // The filled part slowly fades in and out while charging
    property real breathe: 1
    SequentialAnimation on breathe {
        running: root.charging && root.active
        loops: Animation.Infinite
        NumberAnimation { to: Theme.dimOpacity; duration: Motion.breatheMs / 2; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: Motion.breatheMs / 2; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) root.breathe = 1
    }

    // ── Waves ──
    // 0..1, how far the waves have travelled; the second wave starts waveDelay later
    property real wave: 0
    readonly property int waveMs: Motion.ms(900)
    readonly property real waveDelay: 0.3
    readonly property real waveOpacity: 0.5

    NumberAnimation {
        id: waveAnim
        target: root
        property: "wave"
        from: 0
        to: 1
        duration: root.waveMs
        easing.type: Easing.OutCubic
    }

    Connections {
        target: KdeConnectService
        function onPulsed() {
            if (Root.Config.kdeConnectWaves && !ShellState.motionReduced && root.active)
                waveAnim.restart()
        }
    }

    // Dimmed while offline
    opacity: active ? 1 : Theme.dimOpacity
    Behavior on opacity {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        visible: root.ringEnabled
        layer.enabled: true
        layer.samples: root.smoothSamples

        // The empty ring
        ShapePath {
            strokeColor: Qt.alpha(root.ringColor, Theme.dimOpacity)
            strokeWidth: root.stroke
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: 0
                sweepAngle: root.fullTurn
            }
        }

        // The filled part: starts at the top and goes clockwise
        ShapePath {
            strokeColor: root.filled > 0 ? Qt.alpha(root.ringColor, root.breathe) : "transparent"
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: -90
                sweepAngle: Math.min(root.fullTurn, root.fullTurn * root.filled)
            }
        }
    }

    // The two waves: rings that grow from the phone out to the battery ring while fading
    Repeater {
        model: 2

        delegate: Rectangle {
            id: waveRing
            required property int index

            readonly property real t: Math.max(0, Math.min(1,
                (root.wave - waveRing.index * root.waveDelay) / (1 - waveRing.index * root.waveDelay)))
            readonly property real fromR: root.size * root.phoneRatio / 2
            readonly property real r: fromR + t * (root.ringRadius - fromR)

            anchors.centerIn: parent
            width: 2 * r
            height: width
            radius: r
            color: "transparent"
            border.width: root.stroke / 2
            border.color: root.color
            opacity: t > 0 && t < 1 ? (1 - t) * root.waveOpacity : 0
        }
    }

    // The phone in the middle (crossed out while offline)
    Text {
        anchors.centerIn: parent
        text: root.active ? "smartphone" : "mobile_off"
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.size * root.phoneRatio
    }

    // A bolt on the phone's screen while it charges
    Text {
        anchors.centerIn: parent
        text: "bolt"
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.size * root.boltRatio
        opacity: root.charging && root.active ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
        }
    }
}