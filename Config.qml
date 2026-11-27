pragma Singleton
import Quickshell

Singleton {
    // Name of the active preset (must match a key in Theme.presetMap)
    property string theme: "kuumo-dark"
    // File name (inside wallpaperDir) of the wallpaper on screen right now. Set by
    // WallpaperService; the wallpaper kept for each theme is saved by that service.
    property string wallpaper: ""

    // Folder of the wallpapers, shared by every theme (each preset lists its own files)
    readonly property string wallpaperDir: Quickshell.shellDir + "/styles/wallpapers/"

    // Soft moonlight halo behind the island
    property bool islandHalo: true

    // Hovering the island opens the extended panel after this long (ms); leaving it closes
    // the panel after the second delay. Longer close delay = more forgiving.
    property int islandHoverOpenMs: 120
    property int islandHoverCloseMs: 400

    // While a panel is open the shell takes the keyboard so ESC can close it.
    // Off means ESC only works when you have clicked the island first.
    property bool panelsTakeKeyboard: true

    // Workspace dots: these many always show, later ones (up to the max) only while
    // they hold a window or are focused
    property int workspacesAlwaysShown: 5
    property int workspacesMax: 10

    // Volume / brightness keys
    property real osdVolumeStep: 0.05        // per key press (0..1)
    property real osdVolumeMax: 1.0          // 1.0 = 100%
    property int osdBrightnessStep: 5        // percent per key press
    property int osdBrightnessMin: 1         // raw brightnessctl value the screen never goes below

    // Control center sliders, used with the keyboard once a slider is clicked or tabbed to:
    // the arrow keys move this much of the whole range, Page Up/Down and Shift+arrows the
    // large step (0..1)
    property real sliderStep: 0.01
    property real sliderLargeStep: 0.10

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

    property bool kdeConnectBatteryRing: true
    property int kdeConnectLowBattery: 20
    property bool kdeConnectWaves: true
    property bool kdeConnectLowWarning: true
    property bool kdeConnectDrop: true
    property string kdeConnectDevice: ""

    // Night Light (hyprsunset): the range of its sliders and where it starts
    property int nightLightMinK: 2500         // warmest, in Kelvin
    property int nightLightMaxK: 9000         // coldest
    property int nightLightDefaultK: 4500     // used until you choose one
    property int nightLightStepK: 50          // the temperature slider moves in steps of this
    property int nightLightMinGamma: 50       // darkest, in percent
    property int nightLightMaxGamma: 100

    // Notifications: how long a toast stays on the island (ms)
    property int notificationToastMs: 5000

    // Switchers (theme, wallpaper): moving over a card previews it once you rest on it
    // this long (ms), so fast scrolling does not apply every card on the way
    property int switcherPreviewDelayMs: 150

    // Wallpaper changes by awww (types: see `awww img --help`). A wallpaper you keep uses
    // wallpaperTransition; previews, theme changes in the theme switcher and the wallpaper
    // restored at startup use wallpaperPreviewTransition ("none" finishes instantly).
    // The duration is in seconds and does not apply to "simple".
    property string wallpaperTransition: "fade"
    property string wallpaperPreviewTransition: "none"
    property real wallpaperTransitionSeconds: 0.8
    property int wallpaperTransitionFps: 60
    // Width (px) of the still thumbnails made from animated wallpapers
    property int wallpaperThumbWidth: 320
    // Dropping image files on the island adds them to the wallpapers (see WallpaperService)
    property bool wallpaperDropEnabled: true
    // With this on, the right half of the island adds the dropped files to every theme
    property bool wallpaperDropAllThemes: true
    // A dragged image must rest on the island this long (ms) before the switcher opens, so
    // dragging past it by accident does nothing. 0 opens at once.
    property int wallpaperDropOpenMs: 500

    // The custom theme (Settings, Appearance): your own colors as #rrggbb. They start as Kuumo Dark.
    property bool customDarkMode: true
    property string customBg: "#0a0a0a"
    property string customSubBg: "#131417"
    property string customElevatedBg: "#1b1d22"
    property string customBorder: "#272a30"
    property string customFgMuted: "#8a909c"
    property string customFg: "#f4f6f9"
    property string customAccent: "#e0ddd8"
    property string customRed: "#e06c75"
    property string customOrange: "#e49567"
    property string customGreen: "#98c379"
    property string customYellow: "#e5c07b"
    property string customBlue: "#61afef"
    property string customPurple: "#c678dd"
    property string customPink: "#e387b1"
    property string customCyan: "#56b6c2"

    // The clipboard island closes this long after a copy (ms), so "Copied" can be seen
    property int clipboardCopyCloseMs: 800
    // Clipboard island: after choosing an item, also paste it into the window you were in
    property bool clipboardAutoPaste: true

    // The text effects (typing, backspace, iris, and the rolling clock are separate): off shows
    // the final text at once. Typing, backspace and iris follow this switch.
    property bool typewriter: true

    // Polkit prompt: the password field shakes after a wrong password
    property bool polkitShake: true
    // Caps lock is read from Hyprland this long after a key press (ms), so the compositor
    // has updated its state by then
    property int capsLockRefreshMs: 40

    // Launcher: the calculator / unit answer on top, and the suggestions for finishing a conversion
    property bool launcherCalculator: true
    property bool launcherBackspaceLeavesCommands: false
    property bool launcherSuggestions: true
    // Launcher: how many result rows show before the list scrolls
    property int launcherMaxRows: 6
    property bool launcherSourceApps: true
    property bool launcherSourceCommands: true
    property bool launcherSourceSettings: true
    property bool launcherSourceFiles: true
    property bool launcherSourceWeb: true
    property bool launcherHeaders: true
    property int launcherGroupMax: 5
    property bool launcherFilesHidden: false
    property string launcherFilesWhere: "home"
    property string launcherWebEngine: "duckduckgo"

    // Animations (Settings, Animations): 1 is the normal speed, above 1 is faster
    property real animationSpeed: 1.0
    // How much the island overshoots when it opens and closes: 0 is none, 1 is a lot.
    // 0.5 is the original feel.
    property real islandBounce: 0.5
    // Turns animations off: springs jump to their target and fades are instant
    property bool reduceMotion: false
    // The clock's digits roll when the time changes; off changes them at once
    property bool clockRoll: true
    // How much the volume/brightness bar overshoots: 0 is none, 1 is the original feel
    property real osdBounce: 1.0
    // How much a highlighted theme or wallpaper card springs when it grows: 0 is none, 1 is a lot
    property real switcherBounce: 0.5
    // Scrolling in the Settings lists: pixels per mouse-wheel notch, and how far the content
    // can be pulled past either end (px)
    property real scrollStep: 90
    property real scrollBounce: 40
}