import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
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

    readonly property bool hasPlayer: MediaService.hasPlayer
    readonly property real rowH: Math.max(layout.artSize, textCol.implicitHeight)

    // Dimmed, not hidden, when no player exists
    property real activeLevel: hasPlayer ? 1 : Theme.dimOpacity
    Behavior on activeLevel {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    width: layout.mediaW
    height: rowH + layout.dividerGap + layout.dividerH
    opacity: reveal * activeLevel
    enabled: IslandState.extended

    // ── Scroll to skip tracks ──
    property real wheelAcc: 0
    property bool wheelCooling: false

    Timer {
        id: cooldown
        interval: Root.Config.mediaScrollCooldown
        onTriggered: root.wheelCooling = false
    }

    WheelHandler {
        enabled: root.hasPlayer
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (root.wheelCooling) return
            root.wheelAcc += event.angleDelta.y
            if (Math.abs(root.wheelAcc) < Root.Config.mediaScrollThreshold) return

            const goNext = (root.wheelAcc > 0) === Root.Config.mediaScrollUpIsNext
            root.wheelAcc = 0
            root.wheelCooling = true
            cooldown.restart()

            if (goNext) MediaService.next()
            else MediaService.previous()
        }
    }

    // ── Track change: the art dips and springs back, the divider surges ──
    property real artTarget: 1

    Spring {
        id: artScale
        target: root.artTarget
        response: Motion.morph.response
        dampingFraction: Motion.morph.damping
        animated: !ShellState.motionReduced
    }

    Component.onCompleted: artScale.snap()

    Timer {
        id: artRelease
        interval: Motion.artDipMs
        onTriggered: root.artTarget = 1
    }

    Connections {
        target: MediaService
        function onTrackChanged(direction) {
            if (!Root.Config.mediaTrackAnimation) return
            root.artTarget = Motion.artDip
            artRelease.restart()
            divider.pulse()
        }
    }

    // ── Album art on the right, with play/pause on hover ──
    ClippingRectangle {
        id: art
        x: root.width - width
        y: (root.rowH - height) / 2
        width: root.layout.artSize
        height: width
        radius: root.layout.artRadius
        color: Theme.elevatedBg
        scale: artScale.value
        transformOrigin: Item.Center

        Image {
            anchors.fill: parent
            source: MediaService.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: art.width * Screen.devicePixelRatio
            sourceSize.height: art.height * Screen.devicePixelRatio
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            opacity: artMouse.containsMouse ? Theme.scrimOpacity : 0
            Behavior on opacity { NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic } }
        }

        Item {
            id: glyph
            anchors.centerIn: parent
            width: root.layout.iconSize
            height: width
            opacity: artMouse.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic } }

            // Play
            Shape {
                anchors.fill: parent
                visible: !MediaService.isPlaying
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Theme.fg
                    strokeWidth: -1
                    startX: 0; startY: 0
                    PathLine { x: glyph.width; y: glyph.height / 2 }
                    PathLine { x: 0; y: glyph.height }
                    PathLine { x: 0; y: 0 }
                }
            }

            // Pause
            Repeater {
                model: 2
                Rectangle {
                    required property int index
                    visible: MediaService.isPlaying
                    width: glyph.width / 3
                    height: glyph.height
                    x: index * (glyph.width - width)
                    color: Theme.fg
                }
            }
        }

        MouseArea {
            id: artMouse
            anchors.fill: parent
            enabled: root.hasPlayer
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: MediaService.togglePlaying()
        }
    }

    // ── Title and artist, right-aligned to the left of the art ──
    Column {
        id: textCol
        width: root.width - root.layout.artSize - root.layout.artGap
        x: art.x - root.layout.artGap - width
        y: (root.rowH - implicitHeight) / 2

        SlideText {
            width: parent.width
            text: MediaService.title
            color: Theme.fg
            pixelSize: Theme.fontSizeSm
            weight: Font.DemiBold
            alignment: Text.AlignRight
            slide: root.layout.textSlide
            direction: MediaService.pendingDirection
            animated: Root.Config.mediaTrackAnimation && !ShellState.motionReduced
        }

        SlideText {
            width: parent.width
            text: MediaService.artist
            color: Theme.fgMuted
            pixelSize: Theme.fontSizeXs
            alignment: Text.AlignRight
            slide: root.layout.textSlide
            direction: MediaService.pendingDirection
            animated: Root.Config.mediaTrackAnimation && !ShellState.motionReduced
        }
    }

    // ── Glowing divider under the track info ──
    GlowDivider {
        id: divider
        y: root.rowH + root.layout.dividerGap
        width: root.width
        height: root.layout.dividerH
        thickness: root.layout.dividerH
        spread: root.layout.dividerGlow
        active: IslandState.extended
        animated: !ShellState.motionReduced
        breathes: Root.Config.mediaDividerBreathes
        surges: Root.Config.mediaDividerSurges
    }
}