pragma Singleton

import Quickshell
import "../modules/island"

// Named IpcRouter because Quickshell already exports IpcHandler.
Scope {
    IpcHandler {
        target: "kuumo"

        function ping(): string {
            return "kuumo"
        }

        function toggleIsland(): void {
            IslandService.toggle()
        }
    }
}
