pragma Singleton
import Quickshell

Singleton {
    // "idle" | "extended" | "control" | "launcher" | "clipboard" | "power" | "theme" | "wallpaper" | "polkit"
    property string mode: "idle"
    readonly property bool extended: mode === "extended"
    readonly property bool control: mode === "control"
    readonly property bool launcher: mode === "launcher"
    readonly property bool clipboard: mode === "clipboard"
    readonly property bool power: mode === "power"
    readonly property bool theme: mode === "theme"
    readonly property bool wallpaper: mode === "wallpaper"
    readonly property bool polkit: mode === "polkit"
    // Any panel open, i.e. the island is not at rest. The OSD does not count: it
    // never takes the keyboard or the screen.
    readonly property bool open: mode !== "idle"

    function expand() { mode = "extended" }
    function collapse() { mode = "idle" }
    function toggleExtended() { extended ? collapse() : expand() }

    function openControl() { mode = "control" }
    function backToExtended() { mode = "extended" }
    function toggleControl() { control ? collapse() : openControl() }

    // The launcher, the clipboard, the power menu and the two switchers open from any
    // mode and close back to rest
    function openLauncher() { mode = "launcher" }
    function toggleLauncher() { launcher ? collapse() : openLauncher() }

    // The launcher on its command list (id "") or straight in one command ("emoji",
    // "settings", ...). LauncherService listens to commandRequested and decides what to do
    // with it (it knows what the launcher shows); wasOpen says whether the launcher was
    // already open when this was asked.
    signal commandRequested(string id, bool wasOpen)
    function openCommand(id) {
        const wasOpen = launcher
        mode = "launcher"
        commandRequested(id, wasOpen)
    }
    function openCommands() { openCommand("") }

    function openClipboard() { mode = "clipboard" }
    function toggleClipboard() { clipboard ? collapse() : openClipboard() }

    function openPower() { mode = "power" }
    function togglePower() { power ? collapse() : openPower() }

    function openTheme() { mode = "theme" }
    function toggleTheme() { theme ? collapse() : openTheme() }

    function openWallpaper() { mode = "wallpaper" }
    function toggleWallpaper() { wallpaper ? collapse() : openWallpaper() }

    // The polkit prompt opens by itself (PolkitService) over whatever is open, and has
    // no toggle: closing it cancels the request
    function openPolkit() { mode = "polkit" }

    // The OSD (volume, brightness) borrows the island for a moment on top of whatever
    // mode it is in, then gives it back.
    property bool osdActive: false
    property string osdKind: "volume"   // "volume" | "brightness"
    function showOsd(kind) {
        osdKind = kind
        osdActive = true
    }
    function hideOsd() { osdActive = false }

    // ESC or a click outside: close every panel. Anything with a pending request
    // listens to `cancelled` and drops it.
    signal cancelled()
    function closeAll() {
        mode = "idle"
        osdActive = false
        cancelled()
    }
}