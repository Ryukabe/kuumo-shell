pragma Singleton
import Quickshell

Singleton {
    // "idle" | "extended" | "control" (OSD, picker come later)
    property string mode: "idle"
    readonly property bool extended: mode === "extended"
    readonly property bool control: mode === "control"
    // Any panel open, i.e. the island is not at rest
    readonly property bool open: mode !== "idle"

    function expand() { mode = "extended" }
    function collapse() { mode = "idle" }
    function toggleExtended() { extended ? collapse() : expand() }

    function openControl() { mode = "control" }
    function backToExtended() { mode = "extended" }
    function toggleControl() { control ? collapse() : openControl() }

    // ESC or a click outside: close every panel. Anything with a pending request
    // listens to `cancelled` and drops it.
    signal cancelled()
    function closeAll() {
        mode = "idle"
        cancelled()
    }
}