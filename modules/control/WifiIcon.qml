import QtQuick
import QtQuick.Shapes
import "../../styles"

// The Wi-Fi icon, drawn as a dot and three arcs. The arcs light up with the signal
// strength, light up one after another while searching, and the whole icon is
// replaced by a cable icon while a cable is connected.
Item {
    id: root

    property int size: Theme.fontSizeLg
    property color color: Theme.fg
    property bool active: true       // false: Wi-Fi is off, the dot dims too
    property int level: 0            // arcs lit, 0..3
    property bool searching: false   // arcs light up one after another
    property bool wired: false       // show the cable icon instead

    width: size
    height: size

    // ── Drawing proportions (fractions of `size`) ──
    readonly property real strokeRatio: 0.1                  // line thickness
    readonly property real dotRatio: 0.2                     // dot diameter
    readonly property real centerYRatio: 0.8                 // where the dot and the arcs' center sit, from the top
    readonly property var radiusRatios: [0.26, 0.46, 0.66]   // inner to outer arc
    readonly property real fanStart: -135                    // degrees: the arcs fan out upward
    readonly property real fanSweep: 90
    readonly property int smoothSamples: 4                   // edge smoothing

    // ── Which arcs are lit ──
    // While searching, 0..3 arcs light up in turn, then it starts over
    property int pulse: 0
    Timer {
        interval: Motion.searchPulseMs
        repeat: true
        running: root.searching && !root.wired
        onTriggered: root.pulse = (root.pulse + 1) % 4
        onRunningChanged: if (!running) root.pulse = 0
    }

    function arcOn(index) { return searching ? pulse > index : level > index }

    // 0..1 per arc, eased so arcs fade in and out
    property real arc0: arcOn(0) ? 1 : 0
    property real arc1: arcOn(1) ? 1 : 0
    property real arc2: arcOn(2) ? 1 : 0
    Behavior on arc0 { NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic } }
    Behavior on arc1 { NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic } }
    Behavior on arc2 { NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic } }

    // An unlit arc is the icon color, dimmed; a lit one is the full color
    function arcColor(amount) {
        return Qt.alpha(color, Theme.dimOpacity + (1 - Theme.dimOpacity) * amount)
    }

    readonly property real stroke: size * strokeRatio
    readonly property real centerY: size * centerYRatio

    // ── The Wi-Fi arcs and dot ──
    Item {
        anchors.fill: parent
        opacity: root.wired ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic } }

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: root.smoothSamples

            ShapePath {
                strokeColor: root.arcColor(root.arc0)
                strokeWidth: root.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.size / 2
                    centerY: root.centerY
                    radiusX: root.size * root.radiusRatios[0]
                    radiusY: root.size * root.radiusRatios[0]
                    startAngle: root.fanStart
                    sweepAngle: root.fanSweep
                }
            }

            ShapePath {
                strokeColor: root.arcColor(root.arc1)
                strokeWidth: root.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.size / 2
                    centerY: root.centerY
                    radiusX: root.size * root.radiusRatios[1]
                    radiusY: root.size * root.radiusRatios[1]
                    startAngle: root.fanStart
                    sweepAngle: root.fanSweep
                }
            }

            ShapePath {
                strokeColor: root.arcColor(root.arc2)
                strokeWidth: root.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.size / 2
                    centerY: root.centerY
                    radiusX: root.size * root.radiusRatios[2]
                    radiusY: root.size * root.radiusRatios[2]
                    startAngle: root.fanStart
                    sweepAngle: root.fanSweep
                }
            }
        }

        // The dot at the bottom
        Rectangle {
            width: root.size * root.dotRatio
            height: width
            radius: width / 2
            x: root.size / 2 - width / 2
            y: root.centerY - height / 2
            color: root.arcColor(root.active ? 1 : 0)
            Behavior on color { ColorAnimation { duration: Motion.fadeIn } }
        }
    }

    // ── The cable icon ──
    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "lan"
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.size
        opacity: root.wired ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic } }
    }
}