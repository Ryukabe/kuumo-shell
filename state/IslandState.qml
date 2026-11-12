pragma Singleton
import Quickshell

Singleton {
    // "idle" | "extended" (OSD, control center, picker come later)
    property string mode: "idle"
    readonly property bool extended: mode === "extended"

    function toggleExtended() { mode = extended ? "idle" : "extended" }
}