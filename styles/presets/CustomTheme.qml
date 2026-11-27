import QtQuick
import "../.." as Root

// Your own theme: the colors are the custom* settings in Config.qml, edited on the Appearance
// page of Settings. It has the same shape as a preset, but it is not in presetIds, so the theme
// switcher does not list it.
QtObject {
    readonly property string name: "Custom"
    readonly property bool darkMode: Root.Config.customDarkMode
    // The wallpaper and custom themes are not in the theme switcher
    readonly property bool dynamic: true
    // Set by Theme.qml: every wallpaper the presets list
    property var wallpapers: []

    readonly property color bg: Root.Config.customBg
    readonly property color subBg: Root.Config.customSubBg
    readonly property color elevatedBg: Root.Config.customElevatedBg
    readonly property color border: Root.Config.customBorder
    readonly property color fgMuted: Root.Config.customFgMuted
    readonly property color fg: Root.Config.customFg
    readonly property color accent: Root.Config.customAccent

    readonly property color red: Root.Config.customRed
    readonly property color orange: Root.Config.customOrange
    readonly property color green: Root.Config.customGreen
    readonly property color yellow: Root.Config.customYellow
    readonly property color blue: Root.Config.customBlue
    readonly property color purple: Root.Config.customPurple
    readonly property color pink: Root.Config.customPink
    readonly property color cyan: Root.Config.customCyan
}