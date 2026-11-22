import QtQuick
import "../styles"

// An on/off switch in the moon style: off is a dark track with a dim knob, on is a bright
// track (a full moon) with a dark knob. It does not flip itself: it says toggled(value) and
// the owner changes `checked`, so a setting stays the single source of truth.
// Like Apple's switch, the knob stretches while pressed and springs across when released.
Item {
    id: root

    property bool checked: false

    // Sizes; the defaults suit a settings row
    property int trackWidth: 44
    property int trackHeight: 24
    property int knobGap: 3
    property int borderWidth: 1
    property real disabledOpacity: 0.4
    // How much wider the knob gets while pressed
    property int pressStretch: 6
    // Animation timings in ms
    property int slideDuration: 280
    property int colorDuration: 200

    signal toggled(bool value)

    implicitWidth: root.trackWidth
    implicitHeight: root.trackHeight
    opacity: root.enabled ? 1 : root.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.fg : Theme.elevatedBg
        border.width: root.borderWidth
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: root.colorDuration; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: knob
        readonly property int size: root.trackHeight - 2 * root.knobGap

        width: size + (mouse.pressed ? root.pressStretch : 0)
        height: size
        radius: height / 2
        y: root.knobGap
        // Anchored to the right edge when on, so the stretch grows toward the middle
        x: root.checked ? root.trackWidth - root.knobGap - width : root.knobGap
        color: root.checked ? Theme.subBg : Theme.fgMuted

        Behavior on x {
            NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
        Behavior on width {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on color { ColorAnimation { duration: root.colorDuration; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}