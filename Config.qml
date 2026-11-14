pragma Singleton
import Quickshell

Singleton {
    // Name of the active preset (must match a key in Theme.presetMap)
    property string theme: "kuumo-dark"
    property string wallpaper: ""

    // Soft moonlight halo behind the island
    property bool islandHalo: true

    // Scrolling over the player skips tracks
    // true: scroll up = next track, false: scroll down = next track
    property bool mediaScrollUpIsNext: false
    // Wheel distance needed for one skip (one mouse notch is 120)
    property int mediaScrollThreshold: 120
    // Ignore further scrolling for this long after a skip (ms), so a touchpad flick skips once
    property int mediaScrollCooldown: 350

    // Music divider: its glow breathes slowly, and surges when the track changes
    property bool mediaDividerBreathes: true
    property bool mediaDividerSurges: true
    // Title/artist slide and the art dip when the track changes
    property bool mediaTrackAnimation: true
}