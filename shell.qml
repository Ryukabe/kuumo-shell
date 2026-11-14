import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Root
import "core"
import "modules/island"
import "state"

ShellRoot {
    IpcRouter {}

    PanelWindow {
        id: win
        anchors {
            top: true
            left: true
            right: true
        }

        // Static surface, as tall as the screen so a click anywhere can close the
        // panels. Never animate this. Only the island inside morphs.
        implicitHeight: win.screen ? win.screen.height : 0
        color: "transparent" // Never change this color 

        // Lets layer rules (blur, animations) find this surface
        WlrLayershell.namespace: "kuumo-shell"

        // While a panel is open the shell takes the keyboard, so ESC reaches it
        WlrLayershell.keyboardFocus: IslandState.open && Root.Config.panelsTakeKeyboard
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        // Windows stay out from under the island. The zone is the idle size plus the
        // gap, so it stays fixed while the island morphs.
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: island.reservedHeight

        // At rest only the island takes input and the rest is click-through. While a
        // panel is open the whole window takes input, so a click anywhere closes it.
        mask: Region { item: IslandState.open ? surface : island.pill }

        Item {
            id: surface
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: IslandState.closeAll()

            // Behind the island: any click that misses it closes every panel
            MouseArea {
                anchors.fill: parent
                enabled: IslandState.open
                acceptedButtons: Qt.AllButtons
                onClicked: IslandState.closeAll()
            }

            Island {
                id: island
                anchors.fill: parent
            }
        }
    }
}