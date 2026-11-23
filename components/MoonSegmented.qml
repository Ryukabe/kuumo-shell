pragma ComponentBehavior: Bound

import QtQuick
import "../styles"
import "../state"

// A row of choices where one is selected, in the moon style. The bright highlight slides to the
// chosen segment, stretched like rubber (the edge it moves toward is quick and bouncy, the other
// edge follows slowly). It does not change `value` itself: it says picked(value) and the owner
// decides.
//   MoonSegmented { options: [{ value: "preset", label: "Presets" }, ...]; value: "preset" }
Item {
    id: root

    // The choices: [{ value: "preset", label: "Presets" }, ...]
    property var options: []
    // The value of the chosen option
    property var value

    // Sizes; the defaults suit a settings row
    property int segmentWidth: 88
    property int controlHeight: 32
    property int inset: 3
    property int borderWidth: 1
    property real disabledOpacity: 0.4

    signal picked(var value)

    readonly property int count: root.options.length
    readonly property int currentIndex: Math.max(0, root.options.findIndex(o => o.value === root.value))

    // Which way the highlight last moved, so the right edge or the left edge leads
    property bool forward: true
    property int lastIndex: 0
    onCurrentIndexChanged: {
        root.forward = root.currentIndex >= root.lastIndex
        root.lastIndex = root.currentIndex
    }

    implicitWidth: root.count * root.segmentWidth + 2 * root.inset
    implicitHeight: root.controlHeight
    opacity: root.enabled ? 1 : root.disabledOpacity

    // The track
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.elevatedBg
        border.width: root.borderWidth
        border.color: Theme.border
    }

    // The two edges of the highlight, as springs of different speed
    Spring {
        id: edgeLeft
        target: root.inset + root.currentIndex * root.segmentWidth
        response: root.forward ? Motion.rubberTrail.response : Motion.rubberLead.response
        dampingFraction: root.forward ? Motion.rubberTrail.damping : Motion.rubberLead.damping
        animated: !ShellState.motionReduced
    }
    Spring {
        id: edgeRight
        target: root.inset + (root.currentIndex + 1) * root.segmentWidth
        response: root.forward ? Motion.rubberLead.response : Motion.rubberTrail.response
        dampingFraction: root.forward ? Motion.rubberLead.damping : Motion.rubberTrail.damping
        animated: !ShellState.motionReduced
    }

    Component.onCompleted: {
        root.lastIndex = root.currentIndex
        edgeLeft.snap()
        edgeRight.snap()
    }

    // The highlight
    Rectangle {
        x: edgeLeft.value
        y: root.inset
        width: Math.max(0, edgeRight.value - edgeLeft.value)
        height: root.height - 2 * root.inset
        radius: height / 2
        color: Theme.fg
    }

    // The labels
    Row {
        x: root.inset
        y: 0
        height: root.height

        Repeater {
            model: root.options

            delegate: Item {
                id: segment
                required property var modelData
                required property int index

                readonly property bool selected: segment.index === root.currentIndex

                width: root.segmentWidth
                height: root.height

                Text {
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: segment.selected ? Theme.subBg : Theme.fgMuted
                    Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: segment.selected ? Font.Medium : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(segment.modelData.value)
                }
            }
        }
    }
}