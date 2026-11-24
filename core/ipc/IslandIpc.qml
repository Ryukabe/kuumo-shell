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
    // Open the launcher on its command list from anywhere, or close it again if it shows
    // the command list already
    function commands(): void { IslandState.openCommands() }
    // Open one command straight away, for example: qs ipc call island command emoji
    // (ids are in CommandService). Calling it again while that view shows closes the island.
    function command(id: string): void { IslandState.openCommand(id) }
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