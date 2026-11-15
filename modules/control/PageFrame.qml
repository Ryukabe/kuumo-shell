import QtQuick
import "../../styles"

// One page of the control center: it fades and slides a little when it is shown or hidden.
Item {
    id: root

    // The control layout block from Island.qml (how far pages slide)
    required property var layout
    // Is this the page being shown?
    required property bool shown
    // Which side it slides in from (1: right, -1: left)
    property int direction: 1

    // 0 (hidden) .. 1 (shown), eased
    property real fade: shown ? 1 : 0
    Behavior on fade {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    opacity: fade
    x: direction * layout.pageSlide * (1 - fade)
    visible: opacity > 0
    enabled: shown
}