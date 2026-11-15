pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../state"

// Wi-Fi and cable status for the control center, read from NetworkManager (nmcli), and
// the actions on Wi-Fi networks: connect, disconnect, forget.
// It re-reads whenever NetworkManager reports a change, and re-reads the signal
// strength every few seconds while the control center is open.
Singleton {
    id: root

    // ── Tuning ──
    readonly property int strongAt: 67          // signal (0..100) at or above this lights 3 arcs
    readonly property int mediumAt: 34          // at or above this lights 2 arcs, below it 1
    readonly property int signalPollMs: 4000    // how often the signal and list are re-read while the panel is open
    readonly property int listPollMs: 10000     // how often the network list is rescanned while it is showing
    readonly property int rescanSettleMs: 3000  // how long a scan takes before its results can be read
    readonly property int connectTimeoutS: 20   // give up connecting after this long
    readonly property int debounceMs: 300       // wait for a burst of changes to finish before re-reading
    readonly property int restartMs: 2000       // wait before restarting the change watcher if it stops

    // ── What NetworkManager says ──
    property bool radioOn: false     // the Wi-Fi switch
    property string wifiState: ""    // state of the Wi-Fi device: connected, connecting..., disconnected, ...
    property string ssid: ""         // name of the connected network
    property int signalStrength: 0   // 0..100, of the connected network
    property bool wired: false       // an ethernet cable is connected

    // ── Worked out from the above ──
    readonly property bool connected: wifiState === "connected"
    readonly property bool connecting: wifiState.startsWith("connecting")

    // How many arcs light up for a signal strength (0..3)
    function levelFor(strength) {
        if (strength <= 0) return 0
        if (strength >= strongAt) return 3
        if (strength >= mediumAt) return 2
        return 1
    }

    // How many arcs light up in the Wi-Fi button's icon
    readonly property int level: connected ? levelFor(signalStrength) : 0

    // The label under the button
    readonly property string statusText: {
        if (wired) return "Ethernet"
        if (!radioOn) return "Wi-Fi"
        if (connecting) return "Searching"
        if (connected) return ssid !== "" ? ssid : "Connected"
        return "Not connected"
    }

    // ── The network list ──
    property bool listOpen: false     // the list page is showing
    property var networks: []         // rows for the list: { ssid, level, secured, known, active }
    property bool scanning: false
    property string busySsid: ""      // the network being connected to
    property string errorSsid: ""     // the network that last failed to connect
    property string errorText: ""

    property var _accessPoints: ({})  // networks in range, by name: { strength, secured, active }
    property var _knownNames: []      // names of the saved Wi-Fi networks
    property string _wifiDevice: ""   // the Wi-Fi card, e.g. wlan0
    property bool _connectingNew: false  // the current connect creates a new saved network

    // The signal and the list are only re-read while the control center is open
    readonly property bool watching: IslandState.control
    onWatchingChanged: if (watching) refresh()

    onRadioOnChanged: {
        if (!radioOn) networks = []
        else if (listOpen) scan()
    }

    // ── Actions ──
    // Re-reads the devices and the Wi-Fi switch (and the list, if it is showing)
    function refresh() {
        if (!devicesProc.running) devicesProc.running = true
        if (!radioProc.running) radioProc.running = true
        if (listOpen) readNetworks()
    }

    // Re-reads the signal strength and name of the connected network
    function readSignal() {
        if (!listProc.running) listProc.running = true
    }

    // Turns Wi-Fi on or off
    function toggle() {
        if (toggleProc.running) return
        const next = !radioOn
        radioOn = next    // show it right away, NetworkManager confirms later
        toggleProc.command = ["nmcli", "radio", "wifi", next ? "on" : "off"]
        toggleProc.running = true
    }

    // The list page opened or closed
    function openList() {
        errorSsid = ""
        errorText = ""
        listOpen = true
        scan()
    }
    function closeList() { listOpen = false }

    // Shows what is known now, and asks for a fresh scan whose results arrive a moment later
    function scan() {
        if (!radioOn) return
        scanning = true
        readNetworks()
        if (!rescanProc.running) rescanProc.running = true
    }

    function readNetworks() {
        if (!accessPointsProc.running) accessPointsProc.running = true
        if (!knownProc.running) knownProc.running = true
    }

    // Connects to a network. A saved one uses its saved settings; a new one uses the
    // password (empty for an open network).
    // Note: the password is visible to other users of this computer in the process
    // list for the moment nmcli runs.
    function connectTo(name, password) {
        if (connectProc.running) return
        const saved = _knownNames.includes(name)
        _connectingNew = !saved
        busySsid = name
        errorSsid = ""
        errorText = ""

        const base = ["nmcli", "--wait", String(connectTimeoutS)]
        if (saved) {
            connectProc.command = base.concat(["connection", "up", "id", name])
        } else {
            const args = ["device", "wifi", "connect", name]
            if (password !== "") args.push("password", password)
            connectProc.command = base.concat(args)
        }
        connectProc.running = true
    }

    // Disconnects from the current network (it stays saved)
    function disconnect() {
        if (_wifiDevice === "" || disconnectProc.running) return
        disconnectProc.command = ["nmcli", "device", "disconnect", _wifiDevice]
        disconnectProc.running = true
    }

    // Removes a saved network
    function forget(name) {
        if (forgetProc.running) return
        forgetProc.command = ["nmcli", "connection", "delete", "id", name]
        forgetProc.running = true
    }

    // A connect attempt ended
    function finishConnect(exitCode) {
        const name = busySsid
        busySsid = ""
        if (exitCode !== 0) {
            errorSsid = name
            errorText = "Couldn't connect"
            // A failed new network leaves a half-made saved network behind: remove it
            if (_connectingNew) forget(name)
        }
        refresh()
    }

    // ── Reading nmcli output ──
    // nmcli -t escapes special characters in names with a backslash; this removes them
    // (named unescapeName because plain "unescape" is a built-in JavaScript name)
    function unescapeName(text) { return text.replace(/\\(.)/g, "$1") }

    // Splits off the first `count` fields; the rest of the line (which may contain ":") is the last one
    function splitFields(line, count) {
        const fields = []
        let rest = line
        for (let i = 0; i < count; i++) {
            const at = rest.indexOf(":")
            fields.push(rest.slice(0, at))
            rest = rest.slice(at + 1)
        }
        fields.push(rest)
        return fields
    }

    // `nmcli -t` prints one device per line as DEVICE:TYPE:STATE
    function parseDevices(text) {
        let wifi = ""
        let device = ""
        let cable = false
        for (const line of text.trim().split("\n")) {
            const parts = line.split(":")
            if (parts[1] === "wifi" && wifi === "") {
                wifi = parts[2]
                device = parts[0]
            } else if (parts[1] === "ethernet" && parts[2] === "connected") {
                cable = true
            }
        }
        wifiState = wifi
        _wifiDevice = device
        wired = cable

        if (connected) {
            readSignal()
        } else {
            ssid = ""
            signalStrength = 0
        }
    }

    // `nmcli -t` lists access points as IN-USE:SIGNAL:SSID; the connected one starts with "*"
    function parseSignal(text) {
        for (const line of text.trim().split("\n")) {
            if (line.charAt(0) !== "*") continue
            const fields = splitFields(line, 2)
            signalStrength = parseInt(fields[1]) || 0
            ssid = unescapeName(fields[2])
            return
        }
    }

    // Networks in range: IN-USE:SIGNAL:SECURITY:SSID. The same network can show up
    // several times (one per router); keep the strongest.
    function parseAccessPoints(text) {
        const found = {}
        for (const line of text.trim().split("\n")) {
            if (line === "") continue
            const fields = splitFields(line, 3)
            const name = unescapeName(fields[3])
            if (name === "") continue    // hidden network
            const entry = found[name] ?? { strength: 0, secured: false, active: false }
            entry.strength = Math.max(entry.strength, parseInt(fields[1]) || 0)
            entry.secured = fields[2] !== "" && fields[2] !== "--"
            entry.active = entry.active || fields[0] === "*"
            found[name] = entry
        }
        _accessPoints = found
        rebuildNetworks()
    }

    // Saved networks: NAME:TYPE. Only Wi-Fi ones count.
    function parseKnown(text) {
        const names = []
        for (const line of text.trim().split("\n")) {
            const at = line.lastIndexOf(":")
            if (at < 0) continue
            if (line.slice(at + 1) === "802-11-wireless") names.push(unescapeName(line.slice(0, at)))
        }
        _knownNames = names
        rebuildNetworks()
    }

    // Puts the list together: connected first, then saved, then strongest, then by name
    function rebuildNetworks() {
        if (!radioOn) {
            networks = []
            return
        }
        const rows = []
        for (const name in _accessPoints) {
            const ap = _accessPoints[name]
            rows.push({
                ssid: name,
                level: levelFor(ap.strength),
                secured: ap.secured,
                known: _knownNames.includes(name),
                active: ap.active
            })
        }
        rows.sort((a, b) => (b.active - a.active) || (b.known - a.known)
            || (b.level - a.level) || a.ssid.localeCompare(b.ssid))
        networks = rows
    }

    // ── nmcli processes ──
    Process {
        id: devicesProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        stdout: StdioCollector { onStreamFinished: root.parseDevices(text) }
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.radioOn = text.trim() === "enabled" }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector { onStreamFinished: root.parseSignal(text) }
    }

    Process {
        id: accessPointsProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector { onStreamFinished: root.parseAccessPoints(text) }
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector { onStreamFinished: root.parseKnown(text) }
    }

    // Asks the card to scan again; the results are ready a moment later
    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: settleTimer.restart()
    }

    Timer {
        id: settleTimer
        interval: root.rescanSettleMs
        onTriggered: {
            root.readNetworks()
            root.scanning = false
        }
    }

    Process { id: toggleProc; onExited: root.refresh() }
    Process { id: disconnectProc; onExited: root.refresh() }
    Process { id: forgetProc; onExited: root.refresh() }

    Process {
        id: connectProc
        onExited: exitCode => root.finishConnect(exitCode)
    }

    // ── Staying up to date ──
    // `nmcli monitor` prints a line for every change; any line means "look again"
    Process {
        id: watcher
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: debounce.restart() }
        onExited: restartTimer.start()
    }

    Timer {
        id: debounce
        interval: root.debounceMs
        onTriggered: root.refresh()
    }

    // If the watcher stops (for example NetworkManager restarted), start it again
    Timer {
        id: restartTimer
        interval: root.restartMs
        onTriggered: watcher.running = true
    }

    // The signal moves without NetworkManager reporting it, so poll it while the panel is open
    Timer {
        interval: root.signalPollMs
        repeat: true
        running: root.watching && (root.connected || root.listOpen)
        onTriggered: {
            root.readSignal()
            if (root.listOpen) root.readNetworks()
        }
    }

    // While the list is showing, scan for new networks now and then
    Timer {
        interval: root.listPollMs
        repeat: true
        running: root.listOpen && root.radioOn
        onTriggered: root.scan()
    }

    Component.onCompleted: refresh()
}