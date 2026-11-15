pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

// Night Light: warms the screen with hyprsunset.
// This service owns the hyprsunset process: turning on starts it, turning off stops it
// (the screen goes back to normal). While it runs, temperature and gamma are changed
// live with `hyprctl hyprsunset`. The settings are saved in state/night-light.json.
Singleton {
    id: root

    // ── Saved settings ──
    readonly property bool enabled: saved.enabled
    readonly property int temperature: saved.temperature   // Kelvin
    readonly property int gamma: saved.gamma               // percent

    // The same values as 0..1 along their sliders
    readonly property real temperatureLevel: clamp01(
        (temperature - Root.Config.nightLightMinK)
        / (Root.Config.nightLightMaxK - Root.Config.nightLightMinK))
    readonly property real gammaLevel: clamp01(
        (gamma - Root.Config.nightLightMinGamma)
        / (Root.Config.nightLightMaxGamma - Root.Config.nightLightMinGamma))

    // The label under the button
    readonly property string statusText: enabled ? temperature + "K" : "Night Light"

    function clamp01(value) { return Math.max(0, Math.min(1, value)) }

    // ── Actions ──
    function toggle() { setEnabled(!enabled) }

    function setEnabled(on) {
        saved.enabled = on
        daemon.running = on
    }

    // From the temperature slider: 0 (warmest) .. 1 (coldest). Moving it turns Night Light on.
    function setTemperatureLevel(level) {
        const range = Root.Config.nightLightMaxK - Root.Config.nightLightMinK
        const step = Root.Config.nightLightStepK
        const raw = Root.Config.nightLightMinK + clamp01(level) * range
        const kelvin = Math.round(raw / step) * step
        if (kelvin === temperature && enabled) return

        saved.temperature = kelvin
        if (enabled) {
            _dirtyTemperature = true
            applyLive()
        } else {
            setEnabled(true)    // starts with the new value
        }
    }

    // From the gamma slider: 0 (darkest) .. 1 (full). Moving it turns Night Light on.
    function setGammaLevel(level) {
        const range = Root.Config.nightLightMaxGamma - Root.Config.nightLightMinGamma
        const percent = Math.round(Root.Config.nightLightMinGamma + clamp01(level) * range)
        if (percent === gamma && enabled) return

        saved.gamma = percent
        if (enabled) {
            _dirtyGamma = true
            applyLive()
        } else {
            setEnabled(true)
        }
    }

    // ── Changing the running hyprsunset ──
    // A slider can send many values a second. Only the latest value waits for its turn,
    // so the commands never pile up.
    property bool _dirtyTemperature: false
    property bool _dirtyGamma: false

    function applyLive() {
        if (ipcProc.running || !daemon.running) return
        if (_dirtyTemperature) {
            _dirtyTemperature = false
            runIpc("temperature", temperature)
        } else if (_dirtyGamma) {
            _dirtyGamma = false
            runIpc("gamma", gamma)
        }
    }

    function runIpc(what, value) {
        ipcProc.command = ["hyprctl", "hyprsunset", what, String(value)]
        ipcProc.running = true
    }

    // If hyprsunset does not accept the live command, start it again with the new values
    function checkIpc(text) {
        if (/unknown|invalid|error|fail|not found/i.test(text)) restartDaemon()
    }

    property bool _restarting: false

    function restartDaemon() {
        if (!daemon.running) return
        _restarting = true
        daemon.running = false
    }

    Process {
        id: ipcProc
        stdout: StdioCollector { onStreamFinished: root.checkIpc(text) }
        onExited: root.applyLive()
    }

    // ── The hyprsunset process ──
    Process {
        id: daemon
        command: ["hyprsunset", "-t", String(root.temperature), "-g", String(root.gamma)]
        onExited: {
            if (root._restarting) {
                root._restarting = false
                running = true
            } else if (root.enabled) {
                // It stopped by itself (not installed, or it crashed): show Night Light as off
                saved.enabled = false
            }
        }
    }

    // ── Saving ──
    FileView {
        id: store
        path: Quickshell.shellPath("state/night-light.json")

        // Until the file exists these defaults apply; the first change creates it
        adapter: JsonAdapter {
            id: saved
            property bool enabled: false
            property int temperature: Root.Config.nightLightDefaultK
            property int gamma: Root.Config.nightLightMaxGamma
        }

        onAdapterUpdated: writeAdapter()

        // If it was on when the shell last closed, turn it on again
        onLoaded: if (saved.enabled) daemon.running = true
    }
}