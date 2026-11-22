pragma Singleton

import QtQuick
import Quickshell

// Sizes of the Settings window and its parts. They could move into Config.qml later.
Singleton {
    readonly property int windowW: 960
    readonly property int windowH: 640
    // The smallest the window can be made
    readonly property int minW: 640
    readonly property int minH: 420
    readonly property int sidebarW: 232
    readonly property int sidebarPad: 12
    readonly property int itemH: 40
    readonly property int itemGap: 4
    readonly property int itemPad: 12
    readonly property int iconGap: 12
    readonly property int searchH: 36
    readonly property int resultH: 52
    readonly property int maxResults: 8
    readonly property int borderW: 1
    readonly property int pagePad: 32
    readonly property int titleSize: 22
    readonly property int sectionGap: 16
    // A settings row: its smallest height and the space around its text
    readonly property int rowH: 56
    readonly property int rowPadX: 16
    readonly property int rowPadY: 12
    // The space between a card's small title and its panel
    readonly property int cardTitleGap: 8
    // A row pointed at by search: how long it stays lit and how long it takes to fade
    readonly property int flashHoldMs: 600
    readonly property int flashFadeMs: 900
    // How visible the highlight is when the pointer is over a sidebar entry
    readonly property real hoverOpacity: 0.5
    // A slider inside a settings row: its width, and the sizes MoonSlider reads from `layout`
    readonly property int sliderW: 260
    readonly property var sliderLayout: ({
        rowH: 28, iconSize: 18, iconGap: 10, pctGap: 10, pctW: 64,
        dotSize: 14, barH: 4, glowReach: 16, btnBorder: 1
    })
}