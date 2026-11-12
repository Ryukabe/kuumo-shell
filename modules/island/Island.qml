import QtQuick
import "../../components"
import "../../styles"
import "../../state"

Item {
    id: root

    property alias pill: pill

    // Per-mode layout: island size, clock size, and clock position.
    // Sizes come from your reference screenshots; tune freely.
    readonly property var layouts: ({
        idle:     { w: 123, h: 26,  clockSize: 12 },
        extended: { w: 435, h: 100, clockSize: 24, padX: 22, padY: 16 }
    })
    readonly property var cur: layouts[IslandState.mode] ?? layouts.idle

    // Measure the clock at each size so it can be centered or left-aligned exactly
    TextMetrics {
        id: mIdle
        text: SystemState.timeText
        font.family: Theme.fontDisplay
        font.weight: Font.DemiBold
        font.pixelSize: root.layouts.idle.clockSize
    }
    TextMetrics {
        id: mExt
        text: SystemState.timeText
        font.family: Theme.fontDisplay
        font.weight: Font.DemiBold
        font.pixelSize: root.layouts.extended.clockSize
    }

    readonly property real clockX: IslandState.extended
        ? layouts.extended.padX
        : (layouts.idle.w - mIdle.width) / 2
    readonly property real clockY: IslandState.extended
        ? layouts.extended.padY
        : (layouts.idle.h - mIdle.height) / 2

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

    IslandPill {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: Math.max(sw.value, 20)
        height: Math.max(sh.value, 12)

        // The one shared clock: it moves and scales, it is never swapped
        Text {
            id: clockText
            x: sx.value
            y: sy.value
            text: SystemState.timeText
            color: Theme.fg
            font.family: Theme.fontDisplay
            font.weight: Font.DemiBold
            font.pixelSize: Math.max(ss.value, 1)
        }

        Text {
            x: sx.value
            y: sy.value + clockText.height + 2
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