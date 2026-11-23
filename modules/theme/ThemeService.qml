pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root
import "../../styles"
import "../../state"

// The data behind the theme switcher: the list of themes (cut down by the search), the saved
// theme, and previewing, keeping and putting back. Root.Config.theme is what the shell shows
// right now (a preview included); committedId is what is saved. settle() brings them together.
// There are three kinds of theme: one of the presets listed in the switcher ("preset"), colors
// made from the wallpaper on screen ("wallpaper"), and your own colors ("custom").
Singleton {
    id: root

    // Reading this from Island.qml starts the service with the shell, so the saved theme
    // is restored at startup
    readonly property bool started: true

    // ── The themes ──
    // One entry per preset, in the order of Theme.presetIds
    readonly property var themes: Theme.presetIds.map(id => ({
        id: id,
        name: Theme.presetMap[id].name,
        preset: Theme.presetMap[id]
    }))

    // What is typed in the search field, and the themes that match it (name or id)
    property string query: ""
    readonly property var results: {
        const q = root.query.trim().toLowerCase()
        if (q === "") return root.themes
        return root.themes.filter(t => t.name.toLowerCase().includes(q) || t.id.includes(q))
    }

    // The saved theme: what comes back when a preview is dropped
    property string committedId: ""

    // Which kind of theme is saved: "preset", "wallpaper" or "custom"
    readonly property string source: root.committedId === "wallpaper" ? "wallpaper"
        : root.committedId === "custom" ? "custom"
        : "preset"

    // The preset that comes back when the source goes back to "preset"
    property string lastPreset: ""

    function indexOf(id) { return root.results.findIndex(t => t.id === id) }

    // Shows a theme without saving it
    function preview(id) {
        if (Theme.presetMap[id]) Root.Config.theme = id
    }

    // Keeps a theme: it becomes the saved one
    function commit(id) {
        if (!Theme.presetMap[id]) return
        root.committedId = id
        if (Theme.presetIds.includes(id)) root.lastPreset = id
        Root.Config.theme = id
        root.save()
    }

    // Switches between the presets, the wallpaper theme and the custom theme
    function setSource(kind) {
        if (kind === "wallpaper" || kind === "custom") {
            root.commit(kind)
            return
        }
        const back = Theme.presetIds.includes(root.lastPreset) ? root.lastPreset : Theme.presetIds[0]
        root.commit(back)
    }

    // Puts the saved theme back, if a preview is showing
    function settle() {
        if (root.committedId !== "" && Root.Config.theme !== root.committedId)
            Root.Config.theme = root.committedId
    }

    Component.onCompleted: {
        if (root.committedId === "") root.committedId = Root.Config.theme
        if (root.lastPreset === "" && Theme.presetIds.includes(Root.Config.theme))
            root.lastPreset = Root.Config.theme
    }

    // Closing the island without choosing (Esc, a click outside, the bind again) drops the preview
    Connections {
        target: IslandState
        function onThemeChanged() {
            if (!IslandState.theme) root.settle()
        }
    }

    // ── Saving: plain JSON in the shell's state folder ──
    // The folder may not exist on a first run, so it is made first
    Process {
        command: ["mkdir", "-p", Quickshell.stateDir]
        running: true
    }

    FileView {
        id: store
        path: Quickshell.statePath("theme.json")
        onLoaded: root.restore(store.text())
        // No saved theme yet: the default stays
        onLoadFailed: error => {}
    }

    function restore(raw) {
        try {
            const data = JSON.parse(raw)
            if (Theme.presetIds.includes(data.preset)) root.lastPreset = data.preset
            if (!Theme.presetMap[data.theme]) return
            root.committedId = data.theme
            if (Theme.presetIds.includes(data.theme)) root.lastPreset = data.theme
            Root.Config.theme = data.theme
        } catch (e) {
            // An unreadable file: the default stays
        }
    }

    function save() {
        store.setText(JSON.stringify({ theme: root.committedId, preset: root.lastPreset }, null, 2))
    }
}