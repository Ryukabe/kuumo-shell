pragma Singleton
import Quickshell

Singleton {
    // Name of the active preset (must match a key in Theme.presetMap)
    property string theme: "kuumo-dark"
    property string wallpaper: ""

    // Soft moonlight halo behind the island
    property bool islandHalo: true

    // While a panel is open the shell takes the keyboard so ESC can close it.
    // Off means ESC only works when you have clicked the island first.
    property bool panelsTakeKeyboard: true

    // Workspace dots: these many always show, later ones (up to the max) only while
    // they hold a window or are focused
    property int workspacesAlwaysShown: 5
    property int workspacesMax: 10

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