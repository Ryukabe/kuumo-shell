import Quickshell
import "ipc"

// All outside-world triggers (keybinds, CLI) land here: one handler file per target in ipc/.
// Usage: qs ipc call island toggle
Scope {
    IslandIpc {}
    OsdIpc {}
    SettingsIpc {}
}