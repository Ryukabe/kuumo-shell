import QtQuick

QtObject {
    readonly property string name: "Everblush"
    readonly property bool darkMode: true

    // Wallpapers of this theme: file names inside styles/wallpaper/
    readonly property var wallpapers: []

    readonly property color bg: "#141b1e"          // Background
    readonly property color subBg: "#232a2d"       // Lighter Background
    readonly property color elevatedBg: "#2d3437"  // base3 of the Doom Emacs port
    readonly property color border: "#363d3f"      // base4 of the Doom Emacs port
    readonly property color fgMuted: "#b3b9b8"     // Light Gray
    readonly property color fg: "#dadada"          // White (Foreground)
    readonly property color accent: "#6cbfbf"      // Cyan, chosen

    readonly property color red: "#e57474"
    readonly property color green: "#8ccf7e"
    readonly property color yellow: "#e5c76b"
    readonly property color blue: "#67b0e8"
    readonly property color purple: "#c47fd5"      // Magenta
    readonly property color cyan: "#6cbfbf"
}