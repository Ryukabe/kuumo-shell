pragma Singleton
import Quickshell

Singleton {
    // "idle" | "extended" | "control" | "launcher" (picker comes later)
    property string mode: "idle"
    readonly property bool extended: mode === "extended"
    readonly property bool control: mode === "control"
    readonly property bool launcher: mode === "launcher"
    // Any panel open, i.e. the island is not at rest. The OSD does not count: it
    // never takes the keyboard or the screen.
    readonly property bool open: mode !== "idle"

    function expand() { mode = "extended" }
    function collapse() { mode = "idle" }
    function toggleExtended() { extended ? collapse() : expand() }

    function openControl() { mode = "control" }
    function backToExtended() { mode = "extended" }
    function toggleControl() { control ? collapse() : openControl() }

    // The launcher opens from any mode and closes back to rest
    function openLauncher() { mode = "launcher" }
    function toggleLauncher() { launcher ? collapse() : openLauncher() }

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