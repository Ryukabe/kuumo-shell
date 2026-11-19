import QtQuick
import Quickshell.Widgets
import "../styles"
import "../state"
import ".." as Root
import "textUnits.js" as Units

// Each letter appears through a circle that opens from its centre, one after another. The
// letters never move. Scripts whose letters join (Bengali, ...) open word by word, with a longer
// wait between words. Setting `text` again plays it again. With Config.typewriter off or reduced
// motion the text shows whole.
Item {
    id: root

    property string text: ""
    // "auto": single characters, or words for joined scripts. Or "characters" / "words".
    property string by: "auto"
    // Hidden until this is true, then it plays
    property bool playing: true

    property color color: Theme.fg
    property font font
    font.family: Theme.fontText
    font.pixelSize: Theme.fontSizeMd

    // The last piece has opened
    signal completed()

    readonly property bool animated: Root.Config.typewriter && !ShellState.motionReduced
    readonly property bool wordwise: root.by === "words"
        || (root.by === "auto" && /[^\u0000-\u024F]/.test(root.text))
    readonly property var units: root.wordwise
        ? root.text.split(/(\s+)/).filter(s => s.length > 0)
        : (root.by === "characters" ? root.text.split("") : Units.split(root.text))

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        Repeater {
            model: root.units

            Item {
                id: unit
                required property int index
                required property string modelData

                width: glyph.implicitWidth
                height: glyph.implicitHeight

                // 0 = closed, 1 = fully open
                property real open: root.animated ? 0 : 1
                // The circle must reach past the corners of the letter's box
                readonly property real reach: Math.sqrt(width * width + height * height) + root.font.pixelSize

                // The circle: the letter stays where it is and is seen through the opening
                ClippingRectangle {
                    id: iris
                    width: unit.open * unit.reach
                    height: width
                    radius: width / 2
                    x: (unit.width - width) / 2
                    y: (unit.height - height) / 2
                    color: "transparent"

                    Text {
                        id: glyph
                        x: -iris.x
                        y: -iris.y
                        text: unit.modelData
                        color: root.color
                        font: root.font
                    }
                }

                SequentialAnimation {
                    id: reveal
                    PauseAnimation {
                        duration: unit.index * (root.wordwise ? Motion.irisWordStagger : Motion.irisStagger)
                    }
                    NumberAnimation {
                        target: unit
                        property: "open"
                        from: 0
                        to: 1
                        duration: Motion.irisMs
                        easing.type: Easing.OutCubic
                    }
                    onStopped: if (unit.open >= 1 && unit.index === root.units.length - 1) root.completed()
                }

                Component.onCompleted: if (root.animated && root.playing) reveal.start()

                Connections {
                    target: root
                    function onPlayingChanged() {
                        if (root.playing && root.animated) {
                            unit.open = 0
                            reveal.restart()
                        }
                    }
                }
            }
        }
    }

    // Waiting for `playing`: nothing shows yet
    opacity: root.playing ? 1 : 0
}