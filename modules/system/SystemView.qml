import QtQuick
import "../../state"
import "../../styles"

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: SystemState.volume > 0 ? Math.round(SystemState.volume * 100) + "%" : "System"
        color: SystemState.volume > 0 ? Theme.colors.fg : Theme.colors.muted
        font.pixelSize: 12
        font.family: Theme.fontFamily
    }
}
