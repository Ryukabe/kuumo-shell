pragma Singleton

import QtQuick
import Quickshell

// What the Settings window is showing: whether it is open, and which page.
Singleton {
    id: root

    property bool open: false
    property string page: "home"

    // The id of a setting to point out after search opened its page; a row whose id matches
    // can highlight itself. Empty when nothing is pointed out.
    property string highlight: ""

    // The folder next to this file that holds the page components
    readonly property string pagesDir: "pages/"

    // id: used in code and over IPC. file: the page component inside pagesDir.
    // keywords: other words that should find the page in the search.
    readonly property var pages: [
        { id: "home", title: "Home", icon: "home", file: "HomeSettings.qml",
          keywords: "welcome overview start" },
        { id: "appearance", title: "Appearance", icon: "palette", file: "AppearanceSettings.qml",
          keywords: "theme wallpaper colors color dark moon blur" },
        { id: "island", title: "Island", icon: "web_asset", file: "IslandSettings.qml",
          keywords: "halo glow moonlight pill clock extended animation" },
        { id: "control-center", title: "Control Center", icon: "tune", file: "ControlCenterSettings.qml",
          keywords: "wifi night light volume brightness tiles sliders focus phone" },
        { id: "launcher", title: "Launcher", icon: "search", file: "LauncherSettings.qml",
          keywords: "apps search calculator converter emoji commands" },
        { id: "clipboard", title: "Clipboard", icon: "content_paste", file: "ClipboardSettings.qml",
          keywords: "history copy paste pins images" },
        { id: "notifications", title: "Notifications", icon: "notifications", file: "NotificationsSettings.qml",
          keywords: "toast popups focus sound dismiss" },
        { id: "display", title: "Display", icon: "brightness_6", file: "DisplaySettings.qml",
          keywords: "night light screen warm temperature gamma brightness" },
        { id: "about", title: "About", icon: "info", file: "AboutSettings.qml",
          keywords: "version credits license help info" }
    ]

    readonly property var current: root.pages.find(p => p.id === root.page) ?? root.pages[0]

    // Switch page (an unknown id is ignored)
    function goTo(id) {
        if (!root.pages.some(p => p.id === id)) return
        root.page = id
        root.highlight = ""
    }

    // Open the page of a search result, and point out the setting if the result is one
    function openEntry(entry) {
        root.goTo(entry.page)
        root.highlight = entry.id !== entry.page ? entry.id : ""
    }

    // Open the window, on a page if one is given
    function show(id) {
        if (id) root.goTo(id)
        root.open = true
    }

    function hide() { root.open = false }
    function toggle() { root.open = !root.open }
}