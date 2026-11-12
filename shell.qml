import QtQuick
import Quickshell
import "modules/island"

ShellRoot {
    PanelWindow {
        anchors.top: true
        margins.top: 8

        // Static surface: never animate this. Only the island inside morphs.
        implicitWidth: 600
        implicitHeight: 140
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Only the island itself takes input; the rest of the window is click-through
        mask: Region { item: island.pill }

        Island {
            id: island
            anchors.fill: parent
        }
    }
}