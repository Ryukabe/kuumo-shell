import QtQuick

QtObject {
    readonly property string name: "Kuumo Dark"
    readonly property bool darkMode: true

    // Wallpapers of this theme: file names inside styles/wallpaper/
    readonly property var wallpapers: [
        "Red Moon.png", "Dark Mesh Wallpaper.png","Kai Notebook - NOIR Desktop.png"
    ]

    readonly property color bg: "#0a0a0a"          // Void Night (main background)
    readonly property color subBg: "#131417"       // Moonlit Slate (island and surfaces)
    readonly property color elevatedBg: "#1b1d22"  // Cloud Shadow (pills, hover, popups)
    readonly property color border: "#272a30"      // Horizon Mist
    readonly property color fgMuted: "#8a909c"     // Dim Starlight (lifted for contrast on elevated surfaces)
    readonly property color fg: "#f4f6f9"          // Cloud Moon
    readonly property color accent: "#e0ddd8"      // Full Moon (warm moonlight)

    readonly property color red: "#e06c75"
    readonly property color orange: "#e49567"
    readonly property color yellow: "#e5c07b"
    readonly property color green: "#98c379"
    readonly property color cyan: "#56b6c2"
    readonly property color blue: "#61afef"
    readonly property color purple: "#c678dd"
    readonly property color pink: "#e387b1"
}