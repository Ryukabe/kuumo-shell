import Quickshell.Io
import "../../state"

// qs ipc call island <function>
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
    // Open the wallpaper switcher from anywhere, or close it again if it is open
    function wallpaper(): void { IslandState.toggleWallpaper() }
    // Close every panel and cancel pending requests (what ESC does)
    function close(): void { IslandState.closeAll() }
}