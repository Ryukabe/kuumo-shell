import QtQuick
import "../../styles"

Item {
    implicitWidth: title.implicitWidth
    implicitHeight: Theme.barHeight

    Text {
        id: title
        anchors.verticalCenter: parent.verticalCenter
        text: MediaService.title.length > 0 ? MediaService.title : "Media"
        color: MediaService.title.length > 0 ? Theme.colors.fg : Theme.colors.muted
        font.pixelSize: 12
        font.family: Theme.fontFamily
    }
}
