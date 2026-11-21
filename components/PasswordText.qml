pragma ComponentBehavior: Bound

import QtQuick
import "../styles"
import "../state"

// A password as dots, with an eye button. Pressing it turns the dots into the characters one
// after another: each dot shrinks away as its character grows in. Pressing again turns them back
// into dots at once. The font is monospaced, so nothing shifts. `trigger: "hover"` reveals while
// the pointer is over it instead. With reduced motion the characters appear at once.
Item {
    id: root

    property string text: ""
    property string dot: "•"
    property bool revealed: false
    property bool showButton: true
    // "click" or "hover"
    property string trigger: "click"

    property color color: Theme.fg
    property color buttonColor: Theme.fgMuted
    property font font
    font.family: Theme.fontMono
    font.pixelSize: Theme.fontSizeMd

    // The eye was pressed (or the pointer came or went with trigger "hover")
    signal toggled(bool revealed)

    readonly property bool animated: !ShellState.motionReduced

    function toggle() {
        root.revealed = !root.revealed
        root.toggled(root.revealed)
    }

    TextMetrics {
        id: metrics
        font: root.font
        text: "M"
    }

    implicitWidth: row.implicitWidth
    implicitHeight: metrics.height

    HoverHandler {
        enabled: root.trigger === "hover"
        onHoveredChanged: {
            root.revealed = hovered
            root.toggled(hovered)
        }
    }

    Row {
        id: row
        spacing: Theme.spacingSm

        Row {
            id: cells

            Repeater {
                model: root.text.length

                Item {
                    id: cell
                    required property int index

                    readonly property string ch: root.text.charAt(index)
                    // 0 = a dot, 1 = the character
                    property real turn: 0

                    width: metrics.advanceWidth
                    height: metrics.height

                    Text {
                        anchors.centerIn: parent
                        text: root.dot
                        color: root.color
                        font: root.font
                        scale: 1 - cell.turn
                        opacity: 1 - cell.turn
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.ch
                        color: root.color
                        font: root.font
                        scale: cell.turn
                        opacity: cell.turn
                    }

                    SequentialAnimation {
                        id: show
                        PauseAnimation { duration: cell.index * Motion.passwordStagger }
                        NumberAnimation {
                            target: cell
                            property: "turn"
                            to: 1
                            duration: Motion.passwordMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: cell.turn = root.revealed ? 1 : 0

                    Connections {
                        target: root
                        function onRevealedChanged() {
                            show.stop()
                            if (root.revealed && root.animated) show.start()
                            else cell.turn = root.revealed ? 1 : 0
                        }
                    }
                }
            }
        }

        // The eye
        Text {
            visible: root.showButton
            height: metrics.height
            verticalAlignment: Text.AlignVCenter
            text: root.revealed ? "visibility_off" : "visibility"
            color: root.buttonColor
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeLg

            MouseArea {
                anchors.fill: parent
                enabled: root.trigger === "click"
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggle()
            }
        }
    }
}