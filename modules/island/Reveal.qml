import QtQuick
import "../../styles"
import "../../state"

// How far one mode's content has appeared (0..1), for Island.qml. The content shows over the
// later part of the island's growth, and hides fast when the mode ends or an OSD takes over.
//   Reveal { current: sw.value; startSize: idleWidth; endSize: modeWidth; active: IslandState.launcher }
// `value` is the number to give the mode's view as its `reveal`.
QtObject {
    id: root

    // The island's size now, along the axis this mode is measured on (a spring value)
    required property real current
    // The size where the content starts to appear, and where it has fully appeared
    required property real startSize
    required property real endSize
    // Whether the mode is on (an IslandState flag)
    required property bool active
    // Most modes give way to an OSD. The OSD and the toast do not.
    property bool hideOnOsd: true

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    // How far the island has grown from startSize to endSize
    readonly property real growth: root.clamp01((root.current - root.startSize) / (root.endSize - root.startSize))

    // The content appears over the later part of the growth
    readonly property real revealed: root.clamp01((root.growth - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))

    // 1 while the mode is on. Appearing is instant (the growth does the pacing); leaving
    // takes Motion.fadeOut.
    property real shown: root.active && !(root.hideOnOsd && IslandState.osdActive) ? 1 : 0
    Behavior on shown {
        NumberAnimation {
            duration: root.hideOnOsd
                ? (root.shown > 0 || IslandState.osdActive || !root.active ? Motion.fadeOut : 0)
                : (root.active ? 0 : Motion.fadeOut)
            easing.type: Easing.OutCubic
        }
    }

    readonly property real value: root.revealed * root.shown
}