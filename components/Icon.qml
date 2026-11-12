import QtQuick
import "../styles"

Text {
    id: root

    property string name: ""

    text: name
    color: Theme.colors.fg
    font.pixelSize: 14
    font.family: Theme.fontFamily
}
