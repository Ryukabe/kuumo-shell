pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.." as Root

Singleton {
    id: root

    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    function find(id) {
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id === id) return ws
        }
        return null
    }

    // State of the dot for workspace `id`. The first few always show; later ones show
    // only while they hold a window or are focused, and go away when empty again.
    function stateFor(id) {
        const ws = find(id)
        const occupied = ws !== null && ws.toplevels.values.length > 0
        const focused = id === focusedId
        return {
            occupied: occupied,
            focused: focused,
            shown: id <= Root.Config.workspacesAlwaysShown || occupied || focused
        }
    }

    function activate(id) {
        const ws = find(id)
        if (ws) {
            ws.activate()
            return
        }
        // An empty workspace doesn't exist yet, so go there with a dispatcher. Lua mode
        // (Hyprland 0.55+) takes a Lua expression, older configs the classic string.
        Hyprland.dispatch(Hyprland.usingLua
            ? 'hl.dsp.focus({ workspace = "' + id + '" })'
            : "workspace " + id)
    }
}