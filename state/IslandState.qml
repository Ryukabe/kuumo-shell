pragma Singleton
import Quickshell

Singleton {
    // "idle" | "extended" (OSD, control center, picker come later)
    property string mode: "idle"
    readonly property bool extended: mode === "extended"

    function expand() { mode = "extended" }
    function collapse() { mode = "idle" }
    function toggleExtended() { extended ? collapse() : expand() }
}