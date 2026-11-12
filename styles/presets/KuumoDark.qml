import QtQuick

QtObject {
    readonly property bool darkMode: true

    readonly property color bg: "#0a0a0a"          // Void Night (main background)
    readonly property color subBg: "#131417"       // Moonlit Slate (island and surfaces)
    readonly property color elevatedBg: "#1b1d22"  // Cloud Shadow (pills, hover, popups)
    readonly property color border: "#272a30"      // Horizon Mist
    readonly property color fgMuted: "#7e8490"     // Dim Starlight
    readonly property color subtext: "#7e8490"
    readonly property color fg: "#f4f6f9"          // Cloud Moon
    readonly property color accent: "#ffffff"      // Full Moon

    readonly property color red: "#e06c75"
    readonly property color green: "#98c379"
    readonly property color yellow: "#e5c07b"
    readonly property color blue: "#61afef"
    readonly property color purple: "#c678dd"
    readonly property color cyan: "#56b6c2"
}