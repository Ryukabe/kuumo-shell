import QtQuick
import "../styles"

Rectangle {
    id: root

    property string label: ""
    property bool checked: false
    signal clicked()

    implicitWidth: labelText.implicitWidth + 16
    implicitHeight: 28
    radius: height / 2
    color: checked ? Theme.colors.accent : Theme.colors.pill

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: Theme.colors.fg
        font.pixelSize: 12
        font.family: Theme.fontFamily
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
