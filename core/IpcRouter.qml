import Quickshell
import Quickshell.Io
import "../state"

// All outside-world triggers (keybinds, CLI) land here.
// Usage: qs -p ~/Projects/kuumo-shell ipc call island toggle
Scope {
    IpcHandler {
        target: "island"

        function toggle(): void { IslandState.toggleExtended() }
        function expand(): void { IslandState.expand() }
        function collapse(): void { IslandState.collapse() }
    }
}