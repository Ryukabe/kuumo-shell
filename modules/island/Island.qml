import QtQuick
import QtQuick.Effects
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"
import "../media"
import "../workspaces"

Item {
    id: root

    property alias pill: pill

    // Gap between the screen edge and the island, and the space the island reserves
    // for windows. Based on the idle size only, so it never changes during a morph.
    readonly property int topGap: 8
    readonly property int reservedHeight: topGap + layouts.idle.h

    // How far the moonlight halo reaches past the pill
    readonly property int haloReach: 24

    // The clock is drawn once at its largest size and scaled down, so text
    // never re-rasterizes (and never steps in whole pixels) during a morph.
    readonly property int fullClockSize: 24

    // Padding around the clock (and date) for the area you tap
    readonly property int tapPad: 6

    // Widths are even so the settled island sits on whole pixels.
    readonly property var layouts: ({
        idle:     { w: 124, h: 32,  clockSize: 12 },
        extended: {
            w: 436, h: 100, clockSize: 24, padX: 22, dateGap: 2,
            // Music side: art on the right, track info to its left, divider below
            mediaW: 190, artSize: 32, artGap: 10, artRadius: 6, iconSize: 12,
            textSlide: 8,
            dividerGap: 12, dividerH: 2, dividerGlow: 12,
            // Workspace dots under the divider
            dotsGap: 8, dotSize: 6, dotActiveW: 16, dotGap: 6, dotHit: 4
        },
        // clockCenterY: how far below the top edge the small clock's middle sits
        control: { w: 312, h: 380, clockSize: 12, padX: 16, clockCenterY: 16 }
    })
    readonly property var cur: layouts[IslandState.mode] ?? layouts.idle

    readonly property real idleScale: layouts.idle.clockSize / fullClockSize
    readonly property real extClockScale: layouts.extended.clockSize / fullClockSize
    readonly property real ctlClockScale: layouts.control.clockSize / fullClockSize

    // Height of the clock + date block when extended, used to center it vertically
    readonly property real clockBlockH:
        clock.implicitHeight * extClockScale
        + layouts.extended.dateGap + dateText.implicitHeight

    // Where the clock sits inside the pill, per mode
    readonly property real clockX: IslandState.extended
        ? layouts.extended.padX
        : IslandState.control
            ? layouts.control.padX
            : (layouts.idle.w - clock.implicitWidth * idleScale) / 2
    readonly property real clockY: IslandState.extended
        ? (layouts.extended.h - clockBlockH) / 2
        : IslandState.control
            ? layouts.control.clockCenterY - clock.implicitHeight * ctlClockScale / 2
            : (layouts.idle.h - clock.implicitHeight * idleScale) / 2

    // The area you tap: around the clock and date when extended (opens the control
    // center), around the small clock when in the control center (goes back)
    readonly property rect extTap: Qt.rect(
        layouts.extended.padX - tapPad,
        (layouts.extended.h - clockBlockH) / 2 - tapPad,
        Math.max(clock.implicitWidth * extClockScale, dateText.implicitWidth) + 2 * tapPad,
        clockBlockH + 2 * tapPad)
    readonly property rect ctlTap: Qt.rect(
        layouts.control.padX - tapPad,
        layouts.control.clockCenterY - clock.implicitHeight * ctlClockScale / 2 - tapPad,
        clock.implicitWidth * ctlClockScale + 2 * tapPad,
        clock.implicitHeight * ctlClockScale + 2 * tapPad)
    readonly property rect tapRect: IslandState.control ? ctlTap : extTap

    // The right column (music, divider, workspace dots) is centered as one block
    readonly property real rightColH: media.height + layouts.extended.dotsGap + dots.height
    readonly property real rightColY: Math.round((layouts.extended.h - rightColH) / 2)

    // One spring preset for everything that morphs, so the island and the clock
    // start and finish together
    component Follow: Spring {
        response: Motion.morph.response
        dampingFraction: Motion.morph.damping
        animated: !ShellState.motionReduced
    }

    Follow { id: sw; target: root.cur.w }
    Follow { id: sh; target: root.cur.h }
    Follow { id: sx; target: root.clockX }
    Follow { id: sy; target: root.clockY }
    Follow { id: ss; target: root.cur.clockSize }

    // Start at rest, not mid-spring, once all targets are known
    Component.onCompleted: {
        sw.snap(); sh.snap(); sx.snap(); sy.snap(); ss.snap()
    }

    // How far the pill has grown from idle to extended (0..1), read from the width
    // spring so everything that fades in stays in step with the morph
    readonly property real growth: Math.max(0, Math.min(1,
        (sw.value - layouts.idle.w) / (layouts.extended.w - layouts.idle.w)))

    // The extended content appears over the later part of the growth
    readonly property real revealed: Math.max(0, Math.min(1,
        (growth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart)))

    // Leaving extended (collapse or control center) hides it fast
    property real shown: IslandState.extended ? 1 : 0
    Behavior on shown {
        NumberAnimation {
            duration: IslandState.extended ? 0 : Motion.fadeOut
            easing.type: Easing.OutCubic
        }
    }

    readonly property real reveal: revealed * shown

    // ── Moonlight halo ──
    // The pill clips its children, so the halo sits behind it as a sibling. The
    // source has the pill's own color and shape and is hidden by the pill itself;
    // only its blurred light shadow shows around the edge.
    Rectangle {
        id: haloSource
        visible: false
        layer.enabled: true
        x: pill.x
        y: pill.y
        width: pill.width
        height: pill.height
        radius: pill.radius
        color: Theme.bg
    }

    MultiEffect {
        visible: Root.Config.islandHalo
        x: haloSource.x
        y: haloSource.y
        width: haloSource.width
        height: haloSource.height
        source: haloSource
        blurMax: root.haloReach
        shadowEnabled: true
        shadowColor: Theme.fg
        shadowOpacity: Theme.haloOpacity
        shadowBlur: 1.0
    }

    IslandPill {
        id: pill

        // No rounding: the spring moves in fractions of a pixel and the GPU draws
        // that smoothly. Rounding made the settle step in whole pixels.
        width: Math.max(sw.value, 20)
        height: Math.max(sh.value, 12)
        x: (root.width - width) / 2
        y: root.topGap

        // Hover highlight behind the clock: shows that it can be tapped
        Rectangle {
            x: root.tapRect.x
            y: root.tapRect.y
            width: root.tapRect.width
            height: root.tapRect.height
            radius: Theme.radiusSmall
            color: Theme.subBg
            opacity: tapArea.containsMouse ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
            }
        }

        // The one shared clock: it moves and scales, it is never swapped
        NumberFlow {
            id: clock
            weight: Font.Bold
            x: sx.value
            y: sy.value
            text: SystemState.timeText
            // Hour tens 0-2, minute tens 0-5, everything else 0-9 (index 2 is the colon)
            rings: [3, 10, 10, 6, 10]
            pixelSize: root.fullClockSize
            animated: !ShellState.motionReduced
            transformOrigin: Item.TopLeft
            scale: ss.value / root.fullClockSize
            layer.enabled: true
            layer.smooth: true
        }

        Text {
            id: dateText
            x: sx.value
            y: sy.value + clock.implicitHeight * clock.scale + root.layouts.extended.dateGap
            text: SystemState.dateText
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
            opacity: root.reveal
        }

        // Temporary: click the pill to toggle idle / extended (not in the control center)
        MouseArea {
            anchors.fill: parent
            enabled: !IslandState.control
            onClicked: IslandState.toggleExtended()
        }

        // Tap the clock: extended opens the control center, the control center goes back
        MouseArea {
            id: tapArea
            x: root.tapRect.x
            y: root.tapRect.y
            width: root.tapRect.width
            height: root.tapRect.height
            enabled: IslandState.control || (IslandState.extended && root.reveal > 0.5)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: IslandState.control ? IslandState.backToExtended() : IslandState.openControl()
        }

        // Declared after the MouseAreas so the art's play/pause click, the dots and the
        // scroll handler sit on top. They follow the pill's right edge.
        MediaView {
            id: media
            layout: root.layouts.extended
            reveal: root.reveal
            anchors.right: parent.right
            anchors.rightMargin: root.layouts.extended.padX
            y: root.rightColY
        }

        WorkspaceDots {
            id: dots
            layout: root.layouts.extended
            reveal: root.reveal
            anchors.right: parent.right
            anchors.rightMargin: root.layouts.extended.padX
            y: root.rightColY + media.height + root.layouts.extended.dotsGap
        }
    }
}