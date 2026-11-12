import QtQuick
import "../../components"
import "../../styles"
import "../../state"

Item {
    id: root

    property alias pill: pill

    // The clock is drawn once at its largest size and scaled down, so text
    // never re-rasterizes (and never steps in whole pixels) during a morph.
    readonly property int fullClockSize: 30

    readonly property var layouts: ({
        idle:     { w: 123, h: 32,  clockSize: 15 },
        extended: { w: 435, h: 100, clockSize: 30, padX: 22, padY: 16 }
    })
    readonly property var cur: layouts[IslandState.mode] ?? layouts.idle

    readonly property real idleScale: layouts.idle.clockSize / fullClockSize

    readonly property real clockX: IslandState.extended
        ? layouts.extended.padX
        : (layouts.idle.w - clock.implicitWidth * idleScale) / 2
    readonly property real clockY: IslandState.extended
        ? layouts.extended.padY
        : (layouts.idle.h - clock.implicitHeight * idleScale) / 2

    // One spring preset for everything that morphs, so the clock stays attached to the island
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

    IslandPill {
        id: pill
        x: Math.round((root.width - width) / 2)
        y: 0
        width: Math.max(Math.round(sw.value), 20)
        height: Math.max(Math.round(sh.value), 12)

        NumberFlow {
            id: clock
            x: sx.value
            y: sy.value
            text: SystemState.timeText
            // Hour tens 0-2, minute tens 0-5, everything else 0-9 (index 2 is the colon)
            rings: [3, 10, 10, 6, 10]
            pixelSize: root.fullClockSize
            animated: !ShellState.motionReduced
            transformOrigin: Item.TopLeft
            scale: ss.value / root.fullClockSize
        }

        Text {
            x: sx.value
            y: sy.value + clock.implicitHeight * clock.scale + 2
            text: SystemState.dateText
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: 11
            opacity: IslandState.extended ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: IslandState.extended ? Motion.fadeIn : Motion.fadeOut
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Temporary: click to toggle idle / extended
        MouseArea {
            anchors.fill: parent
            onClicked: IslandState.toggleExtended()
        }
    }
}