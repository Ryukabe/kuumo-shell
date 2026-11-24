pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../state"

// KDE Connect: the paired phone's status (reachable, battery, network) and its actions (ring,
// ping, send the clipboard, look for it again, open the KDE Connect app).
// The phone is found with kdeconnect-cli; whether it is reachable, its battery and its
// network are read from KDE Connect's D-Bus interface with busctl. It re-reads every few
// seconds while the control center is open. With several phones paired, the first one is used.
Singleton {
    id: root

    // ── Tuning ──
    readonly property int pollMs: 15000    // how often the phone is re-read while the panel is open
    readonly property int noticeMs: 2500   // how long the line under the page's buttons stays
    readonly property int litMs: 700       // how long a button of the page stays lit after it ran

    // ── The phone ──
    property string deviceId: ""
    property string deviceName: ""
    property bool reachable: false     // connected right now
    property int battery: -1           // percent; -1 while unknown
    property bool charging: false
    property string networkType: ""    // the phone's mobile network ("LTE", ...); empty while unknown
    property int signalBars: -1        // 0..4; -1 while unknown

    // ── Feedback for the page ──
    // The action that ran a moment ago ("ring", "ping", "clipboard", "refresh"), or ""
    property string lastAction: ""
    // A short line about what just happened, or ""
    property string notice: ""
    // Said when an action starts, so the phone icons can ripple
    signal pulsed()

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

    // Asks KDE Connect to search the network again (the Refresh button), then reads the status
    function rescan() {
        if (!rescanProc.running) rescanProc.running = true
        announce("refresh", "Looking for " + (deviceName !== "" ? deviceName : "your phone") + "…", false)
    }

    // Makes the phone ring, so you can find it
    function ring() { runAction("--ring", "ring", "Ringing " + deviceName) }

    // Sends a ping, which shows a notification on the phone
    function ping() { runAction("--ping", "ping", "Pinged " + deviceName) }

    function runAction(flag, action, message) {
        if (!reachable || actionProc.running) return
        actionProc.command = ["kdeconnect-cli", "--device", deviceId, flag]
        actionProc.running = true
        announce(action, message, true)
    }

    // Sends the text on the clipboard to the phone (pictures and other things are not sent)
    function sendClipboard() {
        if (!reachable || clipProc.running || shareProc.running) return
        clipProc.running = true
    }

    function shareClipboard(text) {
        if (text === "") {
            announce("clipboard", "The clipboard has no text", false)
            return
        }
        shareProc.command = ["kdeconnect-cli", "--device", deviceId, "--share-text", text]
        shareProc.running = true
        announce("clipboard", "Sent the clipboard to " + deviceName, true)
    }

    // Opens the KDE Connect app (files, messages, ...) and closes the island
    function openApp() {
        Quickshell.execDetached(["kdeconnect-app"])
        IslandState.closeAll()
    }

    // Lights the button of the action for a moment, shows the line under the buttons, and
    // (when wave is true) makes the phone icons ripple
    function announce(action, message, wave) {
        lastAction = action
        notice = message
        litTimer.restart()
        noticeTimer.restart()
        if (wave) pulsed()
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
            networkType = ""
            signalBars = -1
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
            networkType = ""
            signalBars = -1
        }
    }

    // busctl prints each property on its own line: charge as "i 82", isCharging as "b true"
    function parseBattery(text) {
        const lines = text.trim().split("\n")
        const percent = parseInt((lines[0] ?? "").split(" ")[1])
        battery = isNaN(percent) ? -1 : percent
        charging = (lines[1] ?? "") === "b true"
        if (!networkProc.running) networkProc.running = true
    }

    // busctl prints the network type as `s "LTE"` and the signal as "i 3". A phone (or a
    // KDE Connect version) without this information prints nothing, and nothing is shown.
    function parseNetwork(text) {
        const lines = text.trim().split("\n")
        const type = (lines[0] ?? "").match(/^s "(.*)"$/)
        networkType = type ? type[1] : ""
        const bars = parseInt((lines[1] ?? "").split(" ")[1])
        signalBars = isNaN(bars) || bars < 0 || bars > 4 ? -1 : bars
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

    Process {
        id: networkProc
        command: [
            "busctl", "--user", "get-property", "org.kde.kdeconnect",
            "/modules/kdeconnect/devices/" + root.deviceId + "/connectivity_report",
            "org.kde.kdeconnect.device.connectivity_report",
            "cellularNetworkType", "cellularNetworkStrength"
        ]
        stdout: StdioCollector { onStreamFinished: root.parseNetwork(text) }
    }

    Process { id: actionProc }
    Process { id: shareProc }

    // Reads the clipboard as text, then sends it
    Process {
        id: clipProc
        command: ["wl-paste", "--no-newline", "--type", "text"]
        stdout: StdioCollector { onStreamFinished: root.shareClipboard(text) }
    }

    // Asks KDE Connect to look for devices again; when it is done, the status is read
    Process {
        id: rescanProc
        command: ["kdeconnect-cli", "--refresh"]
        onRunningChanged: if (!running) root.refresh()
    }

    Timer {
        id: litTimer
        interval: root.litMs
        onTriggered: root.lastAction = ""
    }

    Timer {
        id: noticeTimer
        interval: root.noticeMs
        onTriggered: root.notice = ""
    }

    // While the panel is open, keep the status fresh
    Timer {
        interval: root.pollMs
        repeat: true
        running: root.watching && root.paired
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}