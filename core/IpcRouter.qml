import Quickshell
import Quickshell.Io
import "../state"
import "../modules/osd"

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
        // Open the launcher from anywhere, or close it again if it is open
        function launcher(): void { IslandState.toggleLauncher() }
        // Open the clipboard history from anywhere, or close it again if it is open
        function clipboard(): void { IslandState.toggleClipboard() }
        // Open the power menu from anywhere, or close it again if it is open
        function power(): void { IslandState.togglePower() }
        // Open the theme switcher from anywhere, or close it again if it is open
        function theme(): void { IslandState.toggleTheme() }
        // Close every panel and cancel pending requests (what ESC does)
        function close(): void { IslandState.closeAll() }
    }

    // Volume and brightness keys
    IpcHandler {
        target: "osd"

        function volumeUp(): void { OsdService.volumeUp() }
        function volumeDown(): void { OsdService.volumeDown() }
        function volumeMute(): void { OsdService.volumeMute() }
        function brightnessUp(): void { OsdService.brightnessUp() }
        function brightnessDown(): void { OsdService.brightnessDown() }
    }
}