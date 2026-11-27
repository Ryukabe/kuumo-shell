import QtQuick
import Quickshell
import "../.." as Root

// A theme made from the wallpaper on screen. The picture is cut down to a handful of colors; the
// most vivid mid-tone one becomes the accent, and the dark surfaces are tinted with its hue. The
// eight status colors stay fixed. It has the same shape as a preset, but it is not in presetIds,
// so the theme switcher does not list it.
QtObject {
    id: root

    readonly property string name: "Wallpaper"
    readonly property bool darkMode: true
    // The wallpaper and custom themes are not in the theme switcher
    readonly property bool dynamic: true
    // Set by Theme.qml: every wallpaper the presets list
    property var wallpapers: []

    // The wallpaper on screen, "" until one has been set
    readonly property string picture: Root.Config.wallpaper !== ""
        ? "file://" + Root.Config.wallpaperDir + Root.Config.wallpaper : ""

    readonly property ColorQuantizer quantizer: ColorQuantizer {
        source: root.picture
        depth: 3
        rescaleSize: 64
    }

    // The colors worked out from the picture
    readonly property var palette: root.derive(root.quantizer.colors)

    function derive(colors) {
        let best = null
        let bestScore = -1
        for (const c of colors) {
            const l = c.hslLightness
            if (l < 0.2 || l > 0.9) continue
            const score = c.hslSaturation * (1 - Math.abs(l - 0.6))
            if (score > bestScore) {
                bestScore = score
                best = c
            }
        }

        // A picture with no color in it (or none worked out yet) gives neutral greys
        const hue = best && best.hslHue >= 0 ? best.hslHue : 0.6
        const tint = best && best.hslHue >= 0 ? 1 : 0
        const sat = best ? Math.max(0.45, Math.min(0.85, best.hslSaturation)) : 0

        return {
            bg: Qt.hsla(hue, 0.14 * tint, 0.045, 1),
            subBg: Qt.hsla(hue, 0.14 * tint, 0.08, 1),
            elevatedBg: Qt.hsla(hue, 0.13 * tint, 0.115, 1),
            border: Qt.hsla(hue, 0.11 * tint, 0.17, 1),
            fgMuted: Qt.hsla(hue, 0.08 * tint, 0.58, 1),
            fg: Qt.hsla(hue, 0.2 * tint, 0.95, 1),
            accent: best ? Qt.hsla(hue, sat, 0.72, 1) : Qt.hsla(0, 0, 1, 1)
        }
    }

    readonly property color bg: root.palette.bg
    readonly property color subBg: root.palette.subBg
    readonly property color elevatedBg: root.palette.elevatedBg
    readonly property color border: root.palette.border
    readonly property color fgMuted: root.palette.fgMuted
    readonly property color fg: root.palette.fg
    readonly property color accent: root.palette.accent

    readonly property color red: "#e06c75"
    readonly property color orange: "#e49567"
    readonly property color green: "#98c379"
    readonly property color yellow: "#e5c07b"
    readonly property color blue: "#61afef"
    readonly property color purple: "#c678dd"
    readonly property color pink: "#e387b1"
    readonly property color cyan: "#56b6c2"
}