import Quickshell
import QtQuick
import "../../components"
import "../../state"
import "../../styles"

ShellWindow {
    visible: SystemState.osdVisible
    anchors.right: true
    anchors.bottom: true
    margins.right: 16
    margins.bottom: 16
    implicitWidth: 240
    implicitHeight: Theme.barHeight
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    IslandPill {
        anchors.fill: parent
        anchors.margins: 0

        PillSlider {
            anchors.centerIn: parent
            width: parent.width - 24
            value: SystemState.osdKind === "brightness" ? SystemState.brightness : SystemState.volume
        }
    }
}
