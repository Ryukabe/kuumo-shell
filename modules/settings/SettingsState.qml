pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

// Saved settings. The settings are the properties of Config.qml; this singleton puts the
// values you changed in Settings on top of them when the shell starts, and writes every
// change to state/settings.json. Only values that differ from the default are saved, so the
// default in Config.qml is what you get again after a reset.
Singleton {
    id: root

    // The Config properties the Settings window may change and save. Add a name here when a
    // page gets a row for it. (theme and wallpaper are not listed: their services save them.)
    readonly property var keys: [
        "islandHalo", "islandHoverOpenMs", "islandHoverCloseMs", "panelsTakeKeyboard",
        "workspacesAlwaysShown", "workspacesMax",
        "osdVolumeStep", "osdVolumeMax", "osdBrightnessStep",
        "mediaScrollUpIsNext", "mediaDividerBreathes", "mediaDividerSurges", "mediaTrackAnimation",
        "notificationToastMs", "clipboardCopyCloseMs",
        "typewriter", "polkitShake"
    ]

    // The values Config.qml starts with, kept so a setting can go back to them
    property var defaults: ({})
    // The values that differ from their default (and are in the file)
    property var saved: ({})

    property bool captured: false

    // A singleton only exists once something uses it. SettingsWindow calls this when the
    // shell starts, so the saved settings are applied even if Settings is never opened.
    function start() { root.captureDefaults() }

    Component.onCompleted: root.captureDefaults()

    function captureDefaults() {
        if (root.captured) return
        root.captured = true
        const found = {}
        for (const key of root.keys) found[key] = Root.Config[key]
        root.defaults = found
    }

    // ── For the Settings pages ──
    // Change a setting: it takes effect at once and is saved
    function set(key, value) {
        if (!root.keys.includes(key)) {
            console.warn("SettingsState: " + key + " is not in the keys list")
            return
        }
        root.captureDefaults()
        Root.Config[key] = value

        const next = Object.assign({}, root.saved)
        if (value === root.defaults[key]) delete next[key]
        else next[key] = value
        root.saved = next
        root.save()
    }

    // Whether a setting differs from its default
    function isChanged(key) { return key in root.saved }

    // Put one setting back to its default
    function reset(key) {
        if (!root.keys.includes(key)) return
        root.set(key, root.defaults[key])
    }

    // Put every setting back to its default
    function resetAll() {
        for (const key of root.keys) root.reset(key)
    }

    // ── Reading and writing the file ──
    function readState(raw) {
        root.captureDefaults()

        let data = null
        try {
            data = JSON.parse(raw)
        } catch (error) {
            // A damaged file is ignored and written again with the next change
            return
        }
        if (data === null || typeof data !== "object") return

        const kept = {}
        for (const key of root.keys) {
            if (!(key in data)) continue
            // A value of the wrong kind (a text where a number belongs) is ignored
            if (typeof data[key] !== typeof root.defaults[key]) continue
            Root.Config[key] = data[key]
            kept[key] = data[key]
        }
        root.saved = kept
    }

    function save() {
        store.setText(JSON.stringify(root.saved, null, 2))
    }

    FileView {
        id: store
        path: Quickshell.shellPath("state/settings.json")
        printErrors: false

        // With no file yet nothing is changed; the first change creates it
        onLoaded: root.readState(store.text())
    }
}