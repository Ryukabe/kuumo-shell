import QtQuick
import Quickshell
import Quickshell.Hyprland
import "core"
import "modules/island"
import "state"

ShellRoot {
    IpcRouter {}

    PanelWindow {
        id: win
        anchors.top: true

        // Static surface: never animate this. Only the island inside morphs.
        implicitWidth: 600
        implicitHeight: 140
        color: "transparent"

        // Windows stay out from under the island. The zone is the idle size plus the
        // gap, so it stays fixed while the island morphs.
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: island.reservedHeight

        // Only the island itself takes input; the rest of the window is click-through
        mask: Region { item: island.pill }

        Island {
            id: island
            anchors.fill: parent
        }
    }

    // While extended, a click anywhere outside the island collapses it
    HyprlandFocusGrab {
        windows: [win]
        active: IslandState.extended
        onCleared: IslandState.collapse()
    }
}