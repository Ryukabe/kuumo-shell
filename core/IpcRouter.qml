import Quickshell
import Quickshell.Io
import "../state"

// All outside-world triggers (keybinds, CLI) land here.
// Usage: qs ipc call island toggle
Scope {
    IpcHandler {
        target: "island"

        function toggle(): void { IslandState.toggleExtended() }
        function expand(): void { IslandState.expand() }
        function collapse(): void { IslandState.collapse() }

        // Open the control center from anywhere, or close it again if it is open
        function control(): void { IslandState.toggleControl() }
        // Close every panel and cancel pending requests (what ESC does)
        function close(): void { IslandState.closeAll() }
    }
}