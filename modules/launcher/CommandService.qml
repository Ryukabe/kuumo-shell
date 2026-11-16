pragma Singleton
import QtQuick
import Quickshell

// The commands of ">" mode in the launcher.
Singleton {
    id: root

    // name is the title, sub the small line under it, icon the icon-font name shown on the
    // row and in the search field, hint the text of the empty search field while the
    // command is open, words are extra search words. ready: false means nothing runs yet.
    readonly property var commands: [
        { id: "wallpaper", name: "Wallpaper switcher", sub: "Pick a wallpaper", icon: "wallpaper", hint: "Search wallpapers", words: "background image", ready: false },
        { id: "theme", name: "Theme switcher", sub: "Change colors and theme", icon: "palette", hint: "Search themes", words: "colors appearance dark light", ready: false },
        { id: "settings", name: "Settings", sub: "Open the settings app", icon: "settings", hint: "Search settings", words: "preferences options config", ready: false },
        { id: "emoji", name: "Emoji picker", sub: "Find and copy an emoji", icon: "emoji_emotions", hint: "Search emoji", words: "emoticon smiley", ready: true },
        { id: "clipboard", name: "Clipboard history", sub: "Paste something you copied before", icon: "content_paste", hint: "Search clipboard", words: "copy paste", ready: false },
        { id: "power", name: "Power actions", sub: "Lock, sleep, restart, shut down", icon: "power_settings_new", hint: "Search actions", words: "lock sleep suspend reboot restart shutdown poweroff logout", ready: false }
    ]

    // How well a command matches: lower is better, -1 is no match
    function score(cmd, q) {
        const name = cmd.name.toLowerCase()
        if (name.startsWith(q)) return 0
        if (name.includes(" " + q)) return 1
        if (name.includes(q)) return 2
        if (cmd.words.includes(q)) return 3
        return -1
    }

    // Matching commands, best match first. Nothing typed lists them all in the order above.
    function search(text) {
        const q = text.trim().toLowerCase()
        if (q === "") return root.commands
        return root.commands
            .map(c => ({ cmd: c, s: root.score(c, q) }))
            .filter(m => m.s >= 0)
            .sort((a, b) => a.s - b.s)
            .map(m => m.cmd)
    }

    // For a command that acts at once (lock, restart): runs it and returns true.
    // Every other command returns false here and the launcher opens its view instead.
    // Nothing acts at once yet.
    function run(cmd) {
        if (!cmd.ready) return false
        // Each instant command is connected here by its id, for example:
        // if (cmd.id === "lock") { ...lock the screen...; return true }
        return false
    }
}