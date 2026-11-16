import QtQuick
import "../../styles"

// A small pill-shaped button with a text, used for actions. It squishes when pressed and
// dims while disabled.
Rectangle {
    id: root

    // The control layout block from Island.qml (sizes)
    required property var layout

    property string text: ""
    property bool danger: false    // red text, for destructive actions

    signal clicked()

    width: label.implicitWidth + 2 * layout.netActionPad
    height: layout.netActionH
    radius: height / 2
    color: Qt.tint(Theme.subBg, Qt.alpha(Theme.border, area.containsMouse ? 1 : 0))
    border.width: layout.btnBorder
    border.color: Theme.border
    scale: area.pressed ? Motion.pressScale : 1
    opacity: enabled ? 1 : Theme.dimOpacity

    Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
    Behavior on scale {
        NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.danger ? Theme.red : Theme.fg
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}