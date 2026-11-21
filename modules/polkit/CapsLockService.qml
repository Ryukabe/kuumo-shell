pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

// Caps lock state, read from Hyprland (`hyprctl devices -j`). Caps lock counts as on
// when any keyboard entry reports it, because only some entries follow it.
Singleton {
    id: root

    property bool on: false

    // Check soon: waits a moment so the compositor has already updated its state
    function refresh() { delay.restart() }

    Timer {
        id: delay
        interval: Root.Config.capsLockRefreshMs
        onTriggered: if (!reader.running) reader.running = true
    }

    Process {
        id: reader
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(this.text).keyboards ?? []
                    root.on = keyboards.some(k => k.capsLock === true)
                } catch (e) {
                    root.on = false
                }
            }
        }
    }
}