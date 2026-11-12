import QtQuick
import "../styles"

Rectangle {
    id: root

    property real value: 0

    implicitWidth: 120
    implicitHeight: 6
    radius: height / 2
    color: Theme.colors.stroke

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: parent.radius
        color: Theme.colors.accent
    }
}
