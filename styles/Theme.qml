pragma Singleton
import QtQuick
import Quickshell
import "presets"
import ".." as Root

Singleton {
    id: root

    // ── Presets (one instance each; add new presets here and in presetIds) ──
    readonly property QtObject _kuumoDark: KuumoDark {}
    readonly property QtObject _everblush: Everblush {}
    readonly property QtObject _tokyoNight: TokyoNight {}
    readonly property QtObject _rosePine: RosePine {}
    readonly property QtObject _ayu: Ayu {}
    readonly property QtObject _wallpaperTheme: WallpaperPalette { wallpapers: root.allWallpapers }
    readonly property QtObject _customTheme: CustomTheme { wallpapers: root.allWallpapers }

    // Every wallpaper the presets list, once each: the wallpaper and custom themes offer all of them
    readonly property var allWallpapers: {
        const all = []
        for (const preset of [_kuumoDark, _everblush, _tokyoNight, _rosePine, _ayu])
            for (const name of preset.wallpapers)
                if (!all.includes(name)) all.push(name)
        return all
    }
    readonly property var presetMap: ({
        "kuumo-dark": _kuumoDark,
        "everblush": _everblush,
        "tokyo-night": _tokyoNight,
        "rose-pine": _rosePine,
        "ayu-dark": _ayu,
        "wallpaper": _wallpaperTheme,
        "custom": _customTheme
    })
    // The order the theme switcher lists them in
    readonly property var presetIds: [
        "kuumo-dark",
        "everblush",
        "tokyo-night",
        "rose-pine",
        "ayu-dark"
    ]

    // ── Single source of truth: the active preset ──
    readonly property var active: presetMap[Root.Config.theme] ?? _kuumoDark

    // ── Colors ──
    readonly property bool darkMode: active.darkMode
    readonly property color bg: active.bg
    readonly property color subBg: active.subBg
    readonly property color elevatedBg: active.elevatedBg
    readonly property color border: active.border
    readonly property color fgMuted: active.fgMuted
    readonly property color fg: active.fg
    readonly property color accent: active.accent
    readonly property color red: active.red
    // A preset that does not define orange or pink yet falls back to its nearest color
    readonly property color orange: active.orange ?? active.yellow
    readonly property color yellow: active.yellow
    readonly property color green: active.green
    readonly property color cyan: active.cyan
    readonly property color blue: active.blue
    readonly property color purple: active.purple
    readonly property color pink: active.pink ?? active.purple

    // ── Opacities ──
    // Content shown but inactive (e.g. the player with nothing playing)
    readonly property real dimOpacity: 0.4
    // Darkening behind an icon drawn over an image
    readonly property real scrimOpacity: 0.55

    // ── Glow (moonlight) ──
    readonly property real glowRest: 0.55        // divider glow strength at rest
    readonly property real glowBreathe: 0.25     // extra strength at the top of a breath
    readonly property real glowSurge: 0.45       // extra strength at the peak of a surge
    readonly property real glowShoulder: 0.3     // strength on the shoulders of the core line
    readonly property real glowShoulderAt: 0.22  // where the shoulders sit along it (0..0.5)
    readonly property real glowPeak: 0.6         // mist strength at its brightest point
    readonly property real glowFalloffAt: 0.5    // how far out the mist has dropped to glowFalloff (0..1)
    readonly property real glowFalloff: 0.35     // share of glowPeak left at that point
    readonly property real haloOpacity: 0.3      // strength of the halo around the island
    readonly property real haloOsdBoost: 0.35    // extra halo strength at full level during an OSD

    // ── Fonts ──
    // Installed by install.sh: inter-font, ttf-jetbrains-mono-nerd
    readonly property string fontDisplay: "Inter"
    readonly property string fontText: "Inter"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    // Icons are Material Symbols ligatures ("volume_up"); also installed: Outlined, Sharp
    readonly property string fontIcon: "Material Symbols Rounded"

    // ── Radii ──
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 14
    readonly property int radiusLarge: 22
    readonly property int radiusFull: 999

    // ── Spacing ──
    readonly property int spacingSm: 6
    readonly property int spacingMd: 10
    readonly property int spacingLg: 16

    // ── Font sizes ──
    readonly property int fontSizeXs: 11
    readonly property int fontSizeSm: 12
    readonly property int fontSizeMd: 14
    readonly property int fontSizeLg: 18

    // ── Text fields ──
    // Width of the blinking cursor
    readonly property int caretWidth: 1
}