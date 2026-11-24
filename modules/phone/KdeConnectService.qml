pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root
import "../settings"
import "../../state"

// KDE Connect: the paired phones and the one in use (reachable, battery, network), and what
// can be done with it (ring, ping, send the clipboard, send files, look again, open the app).
// The phones are found with kdeconnect-cli; whether the phone is reachable, its battery and
// its network are read from KDE Connect's D-Bus interface with busctl. It re-reads every few
// seconds while the control center is open, and once a minute otherwise when the low battery
// warning is on. With several phones paired, the one chosen on the KDE Connect page is used
// (the first one until you choose).
Singleton {
    id: root

    // ── Tuning ──
    readonly property int pollMs: 15000       // how often the phone is re-read while the panel is open
    readonly property int warnPollMs: 60000   // how often it is read while the panel is closed (warning on)
    readonly property int lowResetMargin: 5   // the battery must climb this far above the low level to warn again
    readonly property int noticeMs: 2500      // how long the line on the page stays
    readonly property int litMs: 700          // how long a button of the page stays lit after it ran

    // ── The phones ──
    // The paired phones: [{ id, name }]
    property var devices: []
    // Everything kdeconnect-cli lists (paired or not), while it is sorted out which are paired
    property var listed: []

    // ── The phone in use ──
    property string deviceId: ""
    property string deviceName: ""
    property bool reachable: false     // connected right now
    property int battery: -1           // percent; -1 while unknown
    property bool charging: false
    property string networkType: ""    // the phone's mobile network ("LTE", ...); empty while unknown
    property int signalBars: -1        // 0..4; -1 while unknown

    // ── Feedback for the page ──
    // The action that ran a moment ago ("ring", "ping", "clipboard", "files", "refresh"), or ""
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

    // Files waiting to be sent, and how many were asked for in this round
    property var fileQueue: []
    property int sendTotal: 0
    // True once the low battery warning has been shown, until the battery recovers
    property bool lowWarned: false

    // The phone is re-read often while the control center is open
    readonly property bool watching: IslandState.control
    onWatchingChanged: if (watching) refresh()

    // ── Reading ──
    // Looks for the phones again, then reads the status of the one in use
    function refresh() {
        if (!listProc.running) listProc.running = true
    }

    // Reads only the status of the phone in use (cheaper than refresh)
    function poll() {
        if (!paired) {
            refresh()
            return
        }
        if (!reachableProc.running) reachableProc.running = true
    }

    // Asks KDE Connect to search the network again (the Refresh button), then reads the status
    function rescan() {
        if (!rescanProc.running) rescanProc.running = true
        announce("refresh", "Looking for " + (deviceName !== "" ? deviceName : "your phone") + "…", false)
    }

    // ── Choosing the phone ──
    function selectDevice(id) {
        SettingsState.set("kdeConnectDevice", id)
        applyDevice()
    }

    // The next paired phone, after the one in use (wraps around)
    function nextDevice() {
        if (devices.length < 2) return
        const at = devices.findIndex(d => d.id === deviceId)
        selectDevice(devices[(at + 1) % devices.length].id)
    }

    // Uses the phone chosen in Settings if it is still paired, else the first one
    function applyDevice() {
        const wanted = Root.Config.kdeConnectDevice
        const pick = devices.find(d => d.id === wanted) ?? devices[0] ?? null
        if (!pick) {
            deviceId = ""
            deviceName = ""
            clearStatus()
            return
        }
        const changed = pick.id !== deviceId
        deviceId = pick.id
        deviceName = pick.name
        if (changed) {
            clearStatus()
            lowWarned = false
        }
        if (!reachableProc.running) reachableProc.running = true
    }

    function clearStatus() {
        reachable = false
        battery = -1
        charging = false
        networkType = ""
        signalBars = -1
    }

    // ── Actions ──
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

    // The local file paths among dropped urls (a web address is not sent)
    function localPaths(urls) {
        const paths = []
        for (const url of urls) {
            const text = String(url)
            if (!text.startsWith("file://")) continue
            try {
                paths.push(decodeURIComponent(text.slice(7)))
            } catch (error) {
                paths.push(text.slice(7))
            }
        }
        return paths
    }

    // Sends dropped files to the phone, one after the other
    function sendFiles(urls) {
        if (!reachable) return
        const paths = localPaths(urls)
        if (paths.length === 0) return
        sendTotal += paths.length
        fileQueue = fileQueue.concat(paths)
        announce("files", "Sending " + (sendTotal === 1 ? "1 file" : sendTotal + " files") + "…", true)
        if (!fileProc.running) nextFile()
    }

    // Starts the next waiting file, and says so when all are sent
    function nextFile() {
        if (fileQueue.length === 0) {
            if (sendTotal > 0) {
                announce("files", "Sent " + (sendTotal === 1 ? "1 file" : sendTotal + " files") + " to " + deviceName, false)
                sendTotal = 0
            }
            return
        }
        const path = fileQueue[0]
        fileQueue = fileQueue.slice(1)
        fileProc.command = ["kdeconnect-cli", "--device", deviceId, "--share", path]
        fileProc.running = true
    }

    // Opens the KDE Connect app (files, messages, ...) and closes the island
    function openApp() {
        Quickshell.execDetached(["kdeconnect-app"])
        IslandState.closeAll()
    }

    // Lights the button of the action for a moment, shows the line on the page, and (when
    // wave is true) makes the phone icons ripple
    function announce(action, message, wave) {
        lastAction = action
        notice = message
        litTimer.restart()
        noticeTimer.restart()
        if (wave) pulsed()
    }

    // ── Low battery ──
    // Shows a notification (it appears as a toast on the island) once when the battery drops
    // to the level chosen in Settings, and again only after it has recovered or was charged
    function checkLow() {
        const level = Root.Config.kdeConnectLowBattery
        const low = reachable && !charging && battery >= 0 && battery <= level
        if (low) {
            if (lowWarned || !Root.Config.kdeConnectLowWarning) return
            lowWarned = true
            Quickshell.execDetached([
                "notify-send", "--app-name=KDE Connect", "--icon=phone",
                "Phone battery low", deviceName + " is at " + battery + "%"
            ])
        } else if (charging || battery > level + lowResetMargin) {
            lowWarned = false
        }
    }

    // ── Reading the results ──
    // `kdeconnect-cli -l --id-name-only` prints one phone per line: its id, a space, its name.
    // It lists phones that are not paired too, so the paired ones are asked for next.
    function parseDevices(text) {
        const found = []
        for (const line of text.trim().split("\n")) {
            const at = line.indexOf(" ")
            if (at > 0) found.push({ id: line.slice(0, at), name: line.slice(at + 1) })
        }
        listed = found
        if (!pairedProc.running) pairedProc.running = true
    }

    // busctl prints the paired ids as: as 2 "id1" "id2". If that could not be read, every
    // listed phone counts.
    function parsePaired(text) {
        const ids = []
        const quoted = /"([^"]+)"/g
        let match = quoted.exec(text)
        while (match !== null) {
            ids.push(match[1])
            match = quoted.exec(text)
        }
        devices = ids.length > 0 ? listed.filter(d => ids.includes(d.id)) : listed
        applyDevice()
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
        checkLow()
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
        id: pairedProc
        command: [
            "busctl", "--user", "call", "org.kde.kdeconnect", "/modules/kdeconnect",
            "org.kde.kdeconnect.daemon", "devices", "bb", "false", "true"
        ]
        stdout: StdioCollector { onStreamFinished: root.parsePaired(text) }
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

    // Sends one file; when it is done, the next waiting file starts
    Process {
        id: fileProc
        onRunningChanged: if (!running) root.nextFile()
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

    // While the panel is closed, read the phone once in a while so a low battery is noticed
    Timer {
        interval: root.warnPollMs
        repeat: true
        running: Root.Config.kdeConnectLowWarning && root.paired && !root.watching
        onTriggered: root.poll()
    }

    Component.onCompleted: refresh()
}