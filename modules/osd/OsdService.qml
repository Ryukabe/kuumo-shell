pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../.." as Root
import "../../state"
import "../../styles"

Singleton {
    id: root

    // Icon thresholds (0..1): below lowAt the quietest icon, below midAt the middle one
    readonly property real lowAt: 0.3
    readonly property real midAt: 0.65
    // How close to 0 or 100 counts as having reached the end
    readonly property real endEps: 0.005

    // ── Volume (PipeWire) ──
    readonly property PwNode sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property real volume: {
        const v = root.sink && root.sink.audio ? root.sink.audio.volume : 0
        return isNaN(v) ? 0 : v
    }
    readonly property bool muted: root.sink && root.sink.audio ? root.sink.audio.muted : false

    // ── Brightness (brightnessctl) ──
    property real brightness: 0.5

    // ── What the OSD shows right now ──
    readonly property bool isVolume: IslandState.osdKind === "volume"
    readonly property real level: isVolume
        ? Math.min(1, volume / Root.Config.osdVolumeMax)
        : brightness
    // The bar's light: off while the volume is muted
    readonly property bool lit: isVolume ? !muted : true
    readonly property real haloLevel: lit ? level : 0

    readonly property string iconName: {
        if (isVolume) {
            if (muted || volume <= 0) return "volume_off"
            if (level < lowAt) return "volume_mute"
            if (level < midAt) return "volume_down"
            return "volume_up"
        }
        if (brightness < lowAt) return "brightness_low"
        if (brightness < midAt) return "brightness_medium"
        return "brightness_high"
    }

    // Which way the last change went (1 up, -1 down). Set when the key is pressed, so
    // it is already right when the icon changes. The icon rolls that way.
    property int iconDirection: 1

    // The level reached 0 or 100: the bar bounces off that end
    signal edge(int direction)

    function show(kind) {
        IslandState.showOsd(kind)
        hold.restart()
    }

    Timer {
        id: hold
        interval: Motion.osdHoldMs
        onTriggered: IslandState.hideOsd()
    }

    // ── Volume actions ──
    function adjustVolume(delta) {
        if (!root.sink || !root.sink.audio) return
        iconDirection = delta > 0 ? 1 : -1
        root.sink.audio.muted = false
        const next = Math.max(0, Math.min(Root.Config.osdVolumeMax, root.sink.audio.volume + delta))
        root.sink.audio.volume = next
        show("volume")
        if (next >= Root.Config.osdVolumeMax - endEps) edge(1)
        else if (next <= endEps) edge(-1)
    }

    function volumeUp() { adjustVolume(Root.Config.osdVolumeStep) }
    function volumeDown() { adjustVolume(-Root.Config.osdVolumeStep) }

    function volumeMute() {
        if (!root.sink || !root.sink.audio) return
        iconDirection = root.muted ? 1 : -1
        root.sink.audio.muted = !root.sink.audio.muted
        show("volume")
    }

    // ── Brightness actions ──
    // Key presses that arrive while brightnessctl is still running are added up and
    // applied in one go afterwards, so a held key never loses steps.
    property int _pendingSteps: 0

    function brightnessUp() { stepBrightness(1) }
    function brightnessDown() { stepBrightness(-1) }

    function stepBrightness(dir) {
        iconDirection = dir
        _pendingSteps += dir
        kickBrightness()
        show("brightness")
        // Pressed while already at the end: bounce right away
        if ((dir > 0 && brightness >= 1 - endEps) || (dir < 0 && brightness <= endEps)) edge(dir)
    }

    function kickBrightness() {
        if (brightnessSet.running || _pendingSteps === 0) return
        const n = _pendingSteps
        _pendingSteps = 0
        brightnessSet.command = [
            "brightnessctl", "-m", "-n" + Root.Config.osdBrightnessMin,
            "set", Math.abs(n) * Root.Config.osdBrightnessStep + "%" + (n > 0 ? "+" : "-")
        ]
        brightnessSet.running = true
    }

    // brightnessctl -m prints: device,class,current,percent,max
    function parseBrightness(text) {
        const parts = text.trim().split("\n")[0].split(",")
        const pct = parseInt(parts[3])
        if (isNaN(pct)) return
        const was = brightness
        brightness = pct / 100
        // Just reached an end: bounce off it
        if (brightness >= 1 - endEps && was < 1 - endEps) edge(1)
        else if (brightness <= endEps && was > endEps) edge(-1)
    }

    Process {
        id: brightnessGet
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: root.parseBrightness(text) }
    }

    Process {
        id: brightnessSet
        stdout: StdioCollector { onStreamFinished: root.parseBrightness(text) }
        onExited: root.kickBrightness()
    }

    Component.onCompleted: brightnessGet.running = true
}