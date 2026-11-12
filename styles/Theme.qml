pragma Singleton
import QtQuick
import Quickshell
import "presets"
import ".." as Root

Singleton {
    id: root

    // ── Presets (one instance each; add new presets here) ──
    readonly property QtObject _kuumoDark: KuumoDark {}
    readonly property var presetMap: ({ "kuumo-dark": _kuumoDark })

    // ── Single source of truth: the active preset ──
    readonly property QtObject active: presetMap[Root.Config.theme] ?? _kuumoDark

    // ── Colors ──
    readonly property bool darkMode: active.darkMode
    readonly property color bg: active.bg
    readonly property color subBg: active.subBg
    readonly property color elevatedBg: active.elevatedBg
    readonly property color border: active.border
    readonly property color fgMuted: active.fgMuted
    readonly property color subtext: active.subtext
    readonly property color fg: active.fg
    readonly property color accent: active.accent
    readonly property color red: active.red
    readonly property color green: active.green
    readonly property color yellow: active.yellow
    readonly property color blue: active.blue
    readonly property color purple: active.purple
    readonly property color cyan: active.cyan

    // ── Fonts ──
    readonly property string fontDisplay: "SF Pro Display"
    readonly property string fontText: "SF Pro Text"
    readonly property string fontMono: "SF Pro Mono"

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
    readonly property int fontSizeSm: 12
    readonly property int fontSizeMd: 14
    readonly property int fontSizeLg: 18
}