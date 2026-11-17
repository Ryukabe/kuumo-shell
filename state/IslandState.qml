pragma Singleton
import Quickshell

Singleton {
    // "idle" | "extended" | "control" | "launcher" | "clipboard" | "power"
    property string mode: "idle"
    readonly property bool extended: mode === "extended"
    readonly property bool control: mode === "control"
    readonly property bool launcher: mode === "launcher"
    readonly property bool clipboard: mode === "clipboard"
    readonly property bool power: mode === "power"
    // Any panel open, i.e. the island is not at rest. The OSD does not count: it
    // never takes the keyboard or the screen.
    readonly property bool open: mode !== "idle"

    function expand() { mode = "extended" }
    function collapse() { mode = "idle" }
    function toggleExtended() { extended ? collapse() : expand() }

    function openControl() { mode = "control" }
    function backToExtended() { mode = "extended" }
    function toggleControl() { control ? collapse() : openControl() }

    // The launcher, the clipboard and the power menu open from any mode and close back to rest
    function openLauncher() { mode = "launcher" }
    function toggleLauncher() { launcher ? collapse() : openLauncher() }

    function openClipboard() { mode = "clipboard" }
    function toggleClipboard() { clipboard ? collapse() : openClipboard() }

    function openPower() { mode = "power" }
    function togglePower() { power ? collapse() : openPower() }

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