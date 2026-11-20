pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// One wallpaper in the switcher. Its name opens letter by letter (IrisText) while the card is
// highlighted (by the pointer or the keyboard), on a shade along the bottom edge. The highlighted
// card grows with a spring and gets a ring; a small dot marks the wallpaper kept for the theme.
Item {
    id: root

    // The layout.wallpaper block from Island.qml
    required property var layout
    // One entry of WallpaperService.results: { name, label, animated }
    required property var entry
    // This card is highlighted / holds the kept wallpaper
    required property bool current
    required property bool applied

    // The pointer moved over the card / the card was clicked
    signal hovered()
    signal chosen()

    width: root.layout.cardW
    height: root.layout.cardH

    // The picture: the file itself, or for an animated wallpaper the thumbnail made from its
    // first frame ("" until it is ready)
    readonly property string picture: root.entry.animated
        ? WallpaperService.thumbPath(root.entry.name)
        : "file://" + Root.Config.wallpaperDir + root.entry.name

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

    Component.onCompleted: {
        grow.snap()
        if (root.entry.animated) WallpaperService.ensureThumb(root.entry.name)
    }

    // The card grows around its centre; the row of cards reserves only the resting size.
    // Size and position are whole pixels, so the ring is never cut or blurred on a half pixel.
    ClippingRectangle {
        id: frame
        width: Math.round(root.width * grow.value)
        height: Math.round(root.height * grow.value)
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        radius: root.layout.cardRadius
        color: Theme.subBg
        border.width: root.layout.cardBorder
        border.color: root.current ? Theme.accent : Theme.border
        Behavior on border.color { ColorAnimation { duration: Motion.hoverFade } }

        Image {
            anchors.fill: parent
            visible: status === Image.Ready
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.width * root.layout.selectedScale, root.height * root.layout.selectedScale)
            source: root.picture
        }

        // The shade, while the card is highlighted
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.layout.shadeH
            opacity: root.current || pointer.containsMouse ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
            }
            gradient: Gradient {
                GradientStop { position: 0; color: root.shadeClear }
                GradientStop { position: 1; color: root.shadeFull }
            }
        }

        // The name, opening letter by letter; the clip keeps a long name inside the card
        Item {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: root.layout.cardPad
            width: parent.width - 2 * root.layout.cardPad
            height: nameText.implicitHeight
            clip: true

            IrisText {
                id: nameText
                text: root.entry.label
                playing: root.current || pointer.containsMouse
                color: Theme.fg
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeSm
                font.bold: true
            }
        }

        // Marks the wallpaper kept for the theme
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