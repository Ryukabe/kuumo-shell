pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// One theme in the switcher: its wallpaper (its own colors when it has none), the six colors
// of its palette as dots, and its name, which opens letter by letter (IrisText) while the card is
// highlighted (by the pointer or the keyboard). A shade along the bottom edge keeps the dots and
// the name readable on any picture. The highlighted card grows with a spring and gets a ring; a
// small dot marks the saved theme.
Item {
    id: root

    // The layout.theme block from Island.qml
    required property var layout
    // One entry of ThemeService.themes: { id, name, preset }
    required property var entry
    // This card is highlighted / holds the saved theme
    required property bool current
    required property bool applied

    // The pointer moved over the card / the card was clicked
    signal hovered()
    signal chosen()

    width: root.layout.cardW
    height: root.layout.cardH

    // The card shows the first wallpaper of its theme
    readonly property var wallpapers: root.entry.preset.wallpapers
    readonly property string picture: root.wallpapers.length > 0
        ? "file://" + Root.Config.wallpaperDir + root.wallpapers[0] : ""

    // The palette dots
    readonly property var dots: [
        root.entry.preset.red, root.entry.preset.green, root.entry.preset.yellow,
        root.entry.preset.blue, root.entry.preset.purple, root.entry.preset.cyan
    ]

    // The shade: the island's background color, clear at the top, scrimOpacity strong at the bottom
    readonly property color shadeClear: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0)
    readonly property color shadeFull: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Theme.scrimOpacity)

    // How big the card is right now (1 = resting, selectedScale = highlighted)
    Spring {
        id: grow
        target: root.current ? root.layout.selectedScale : 1
        response: Motion.cardGrow.response
        dampingFraction: Motion.cardGrow.damping
        animated: !ShellState.motionReduced
    }
    Component.onCompleted: grow.snap()

    // The card grows around its centre; the row of cards reserves only the resting size.
    // Size and position are whole pixels, so the ring is never cut or blurred on a half pixel.
    ClippingRectangle {
        id: frame
        width: Math.round(root.width * grow.value)
        height: Math.round(root.height * grow.value)
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        radius: root.layout.cardRadius
        color: root.entry.preset.bg
        border.width: root.layout.cardBorder
        border.color: root.current ? Theme.accent : Theme.border
        Behavior on border.color { ColorAnimation { duration: Motion.hoverFade } }

        // The theme's own colors: what shows when the theme has no wallpaper
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: root.entry.preset.subBg }
                GradientStop { position: 1; color: root.entry.preset.bg }
            }
        }

        Image {
            anchors.fill: parent
            visible: status === Image.Ready
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.width * root.layout.selectedScale, root.height * root.layout.selectedScale)
            source: root.picture
        }

        // The shade along the bottom edge
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.layout.shadeH
            gradient: Gradient {
                GradientStop { position: 0; color: root.shadeClear }
                GradientStop { position: 1; color: root.shadeFull }
            }
        }

        // The name (while highlighted) over the palette dots, at the bottom left
        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: root.layout.cardPad
            width: parent.width - 2 * root.layout.cardPad
            spacing: root.layout.cardTextGap

            // The clip keeps a long name inside the card
            Item {
                width: parent.width
                height: nameText.implicitHeight
                clip: true

                IrisText {
                    id: nameText
                    text: root.entry.name
                    playing: root.current || pointer.containsMouse
                    color: Theme.fg
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeSm
                    font.bold: true
                }
            }

            Row {
                spacing: root.layout.dotGap

                Repeater {
                    model: root.dots

                    Rectangle {
                        required property color modelData
                        width: root.layout.dotSize
                        height: root.layout.dotSize
                        radius: width / 2
                        color: modelData
                    }
                }
            }
        }

        // Marks the saved theme
        Rectangle {
            visible: root.applied
            x: parent.width - width - root.layout.appliedInset
            y: root.layout.appliedInset
            width: root.layout.appliedDot
            height: root.layout.appliedDot
            radius: width / 2
            color: Theme.accent
        }
    }

    // Moving over the card highlights it. This reacts to the pointer moving, not just to a card
    // arriving under it, so the row sliding under a still pointer does not steal the highlight.
    MouseArea {
        id: pointer
        anchors.fill: frame
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        onClicked: root.chosen()
    }
}