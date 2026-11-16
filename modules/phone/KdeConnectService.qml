pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../state"

// KDE Connect: the paired phone's status (reachable, battery) and two actions (ring, ping).
// The phone is found with kdeconnect-cli; whether it is reachable and its battery are read
// from KDE Connect's D-Bus interface with busctl. It re-reads every few seconds while the
// control center is open. With several phones paired, the first one is used.
Singleton {
    id: root

    // ── Tuning ──
    readonly property int pollMs: 15000    // how often the phone is re-read while the panel is open

    // ── The phone ──
    property string deviceId: ""
    property string deviceName: ""
    property bool reachable: false     // connected right now
    property int battery: -1           // percent; -1 while unknown
    property bool charging: false

    // ── Worked out from the above ──
    readonly property bool paired: deviceId !== ""
    readonly property real batteryLevel: battery < 0 ? 0 : battery / 100

    // The label under the button
    readonly property string statusText: {
        if (!paired) return "KDE Connect"
        if (!reachable) return "Offline"
        return battery >= 0 ? battery + "%" : "Connected"
    }

    // The phone is only re-read while the control center is open
    readonly property bool watching: IslandState.control
    onWatchingChanged: if (watching) refresh()

    // ── Actions ──
    // Looks for the phone again, then reads its status
    function refresh() {
        if (!listProc.running) listProc.running = true
    }

    // Makes the phone ring, so you can find it
    function ring() { runAction("--ring") }

    // Sends a ping, which shows a notification on the phone
    function ping() { runAction("--ping") }

    function runAction(flag) {
        if (!reachable || actionProc.running) return
        actionProc.command = ["kdeconnect-cli", "--device", deviceId, flag]
        actionProc.running = true
    }

    // ── Reading the results ──
    // `kdeconnect-cli -l --id-name-only` prints one phone per line: its id, a space, its name
    function parseDevices(text) {
        const line = text.trim().split("\n")[0]
        const at = line.indexOf(" ")
        if (at < 0) {
            // No phone paired
            deviceId = ""
            deviceName = ""
            reachable = false
            battery = -1
            charging = false
            return
        }
        deviceId = line.slice(0, at)
        deviceName = line.slice(at + 1)
        if (!reachableProc.running) reachableProc.running = true
    }

    // busctl prints a boolean as "b true" or "b false"
    function parseReachable(text) {
        reachable = text.trim() === "b true"
        if (reachable) {
            if (!batteryProc.running) batteryProc.running = true
        } else {
            battery = -1
            charging = false
        }
    }

    // busctl prints each property on its own line: charge as "i 82", isCharging as "b true"
    function parseBattery(text) {
        const lines = text.trim().split("\n")
        const percent = parseInt((lines[0] ?? "").split(" ")[1])
        battery = isNaN(percent) ? -1 : percent
        charging = (lines[1] ?? "") === "b true"
    }

    // ── Processes ──
    Process {
        id: listProc
        command: ["kdeconnect-cli", "--list-devices", "--id-name-only"]
        stdout: StdioCollector { onStreamFinished: root.parseDevices(text) }
    }

    Process {
        id: reachableProc
        command: [
            "busctl", "--user", "get-property", "org.kde.kdeconnect",
            "/modules/kdeconnect/devices/" + root.deviceId,
            "org.kde.kdeconnect.device", "isReachable"
        ]
        stdout: StdioCollector { onStreamFinished: root.parseReachable(text) }
    }

    Process {
        id: batteryProc
        command: [
            "busctl", "--user", "get-property", "org.kde.kdeconnect",
            "/modules/kdeconnect/devices/" + root.deviceId + "/battery",
            "org.kde.kdeconnect.device.battery", "charge", "isCharging"
        ]
        stdout: StdioCollector { onStreamFinished: root.parseBattery(text) }
    }

    Process { id: actionProc }

    // While the panel is open, keep the status fresh
    Timer {
        interval: root.pollMs
        repeat: true
        running: root.watching && root.paired
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}