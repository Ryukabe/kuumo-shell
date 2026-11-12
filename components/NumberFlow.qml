pragma ComponentBehavior: Bound

import QtQuick
import "../styles"

// Rolling-digit text for clocks, modeled on NumberFlow (number-flow.barvian.me).
// Every digit is its own spring-driven strip that rolls upward and fades at its edges.
Item {
    id: root

    property string text: "00:00"
    property var rings: []                       // wrap size per character; 10 if unset
    property color color: Theme.fg
    property string fontFamily: Theme.fontDisplay
    property int pixelSize: 24
    property int weight: Font.DemiBold
    property bool animated: true

    readonly property real cellW: Math.ceil(digitMetrics.width)
    readonly property real sepW: Math.ceil(sepMetrics.width)
    readonly property real lineH: Math.ceil(digitMetrics.height)

    implicitWidth: row.implicitWidth
    implicitHeight: lineH

    TextMetrics {
        id: digitMetrics
        text: "0"
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
    }
    TextMetrics {
        id: sepMetrics
        text: ":"
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
    }

    Row {
        id: row

        Repeater {
            model: root.text.length

            delegate: Item {
                id: cell

                required property int index
                readonly property string ch: root.text.charAt(index)
                readonly property bool isDigit: ch >= "0" && ch <= "9"
                readonly property int ring: root.rings[index] ?? 10
                property int lastDigit: -1

                width: isDigit ? root.cellW : root.sepW
                height: root.lineH
                clip: true

                // Signed distance from the visible slot, wrapped around the ring
                function wrap(v) {
                    var r = ring
                    var x = ((v % r) + r) % r
                    return x > r / 2 ? x - r : x
                }

                // A changed digit always rolls upward by the number of steps it moved
                function sync() {
                    if (!isDigit) return
                    var d = parseInt(ch)
                    if (lastDigit < 0) {
                        lastDigit = d
                        spr.target = d
                        spr.snap()
                        return
                    }
                    var steps = ((d - lastDigit) % ring + ring) % ring
                    lastDigit = d
                    spr.target += steps
                }

                onChChanged: sync()
                Component.onCompleted: sync()

                // Units are digit steps, so the rest thresholds are much smaller than for pixels
                Spring {
                    id: spr
                    response: Motion.digit.response
                    dampingFraction: Motion.digit.damping
                    animated: root.animated
                    restDelta: 0.002
                    restSpeed: 0.02
                }

                Repeater {
                    model: cell.isDigit ? cell.ring : 0

                    delegate: Text {
                        required property int index
                        readonly property real d: cell.wrap(index - spr.value)

                        visible: Math.abs(d) < 1
                        width: cell.width
                        height: root.lineH
                        y: d * root.lineH
                        text: String(index)
                        color: root.color
                        font.family: root.fontFamily
                        font.pixelSize: root.pixelSize
                        font.weight: root.weight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: Math.max(0, Math.min(1, 1.5 - 1.5 * Math.abs(d)))
                    }
                }

                Text {
                    anchors.fill: parent
                    visible: !cell.isDigit
                    text: cell.ch
                    color: root.color
                    font.family: root.fontFamily
                    font.pixelSize: root.pixelSize
                    font.weight: root.weight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}