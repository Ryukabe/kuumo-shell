import QtQuick
import "../styles"

// An on/off switch in the moon style: off is a dark track with a dim knob, on is a bright
// track (a full moon) with a dark knob. It does not flip itself: it says toggled(value) and
// the owner changes `checked`, so a setting stays the single source of truth.
Item {
    id: root

    property bool checked: false

    // Sizes; the defaults suit a settings row
    property int trackWidth: 44
    property int trackHeight: 24
    property int knobGap: 3
    property int borderWidth: 1
    property real disabledOpacity: 0.4

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
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
    }

    Rectangle {
        id: knob
        readonly property int size: root.trackHeight - 2 * root.knobGap

        width: size
        height: size
        radius: size / 2
        y: root.knobGap
        x: root.checked ? root.trackWidth - root.knobGap - size : root.knobGap
        color: root.checked ? Theme.subBg : Theme.fgMuted

        Behavior on x {
            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutBack }
        }
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}