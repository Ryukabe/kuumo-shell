pragma ComponentBehavior: Bound

import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

Item {
    id: root

    // The extended layout block from Island.qml
    required property var layout
    // 0..1, how far the extended content has appeared (from Island.qml)
    required property real reveal

    width: layout.mediaW
    height: layout.dotSize
    opacity: reveal
    enabled: IslandState.extended

    Row {
        anchors.right: parent.right
        height: parent.height

        Repeater {
            model: Root.Config.workspacesMax

            delegate: Item {
                id: slot

                required property int index
                readonly property int wsId: index + 1
                readonly property var st: WorkspaceService.stateFor(wsId)

                // Width of the dot itself: a pill when focused, 0 while hidden
                Spring {
                    id: dotW
                    target: !slot.st.shown ? 0
                        : (slot.st.focused ? root.layout.dotActiveW : root.layout.dotSize)
                    response: Motion.dots.response
                    dampingFraction: Motion.dots.damping
                    animated: !ShellState.motionReduced
                }

                // 0..1, how fully the dot has appeared (its gap and fade follow it)
                readonly property real grow: Math.max(0, Math.min(1, dotW.value / root.layout.dotSize))

                width: Math.max(0, dotW.value) + root.layout.dotGap * grow
                height: root.layout.dotSize
                opacity: grow

                Rectangle {
                    anchors.right: parent.right
                    width: Math.max(0, dotW.value)
                    height: parent.height
                    radius: height / 2
                    color: slot.st.focused ? Theme.accent
                        : (slot.st.occupied ? Theme.fgMuted : Theme.border)
                    Behavior on color {
                        ColorAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -root.layout.dotHit
                    enabled: slot.st.shown
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WorkspaceService.activate(slot.wsId)
                }
            }
        }
    }
}