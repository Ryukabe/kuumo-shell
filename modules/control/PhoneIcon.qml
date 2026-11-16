import QtQuick
import QtQuick.Shapes
import "../../styles"

// A phone inside a battery ring: the ring fills with the battery level and breathes while
// the phone charges. The whole icon dims while the phone is offline.
Item {
    id: root

    property int size: Theme.fontSizeLg
    property color color: Theme.fg
    property real level: 0           // battery, 0..1
    property bool active: false      // the phone is reachable
    property bool charging: false

    width: size
    height: size

    // ── Drawing proportions ──
    readonly property real strokeRatio: 0.09    // ring thickness, as a fraction of `size`
    readonly property real phoneRatio: 0.55     // phone symbol size, as a fraction of `size`
    readonly property real fullTurn: 359.9      // a full circle is drawn as just under 360 degrees
    readonly property int smoothSamples: 4      // edge smoothing

    readonly property real stroke: size * strokeRatio
    readonly property real ringRadius: (size - stroke) / 2

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

    // Dimmed while offline
    opacity: active ? 1 : Theme.dimOpacity
    Behavior on opacity {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: root.smoothSamples

        // The empty ring
        ShapePath {
            strokeColor: Qt.alpha(root.color, Theme.dimOpacity)
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
            strokeColor: root.filled > 0 ? Qt.alpha(root.color, root.breathe) : "transparent"
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

    // The phone in the middle
    Text {
        anchors.centerIn: parent
        text: "smartphone"
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.size * root.phoneRatio
    }
}