pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root
import "../../styles"
import "../../state"

// The data behind the wallpaper switcher. A theme lists its wallpapers (file names inside
// Config.wallpaperDir) in its preset; the switcher shows those of the active theme, split into
// static and animated (.gif) ones, and awww puts them on screen. Each theme remembers the
// wallpaper you last kept with it, and a theme change brings that one back (the theme's first
// one until you have kept another). Root.Config.wallpaper is what is on screen right now (a
// preview included); `saved` is what is kept. settle() brings them together.
Singleton {
    id: root

    // Reading this from Island.qml starts the service with the shell, so the saved
    // wallpaper is restored at startup
    readonly property bool started: true

    // ── The wallpapers of the active theme ──
    readonly property string themeId: Root.Config.theme
    readonly property var entries: (Theme.active.wallpapers ?? []).map(name => ({
        name: name,
        label: name.replace(/\.[^.]+$/, ""),
        animated: root.isAnimated(name)
    }))

    // Only .gif files animate in awww
    function isAnimated(name) { return /\.gif$/i.test(name) }

    // The Static / Animated switch, the search, and the entries that match both
    property bool animatedMode: false
    property string query: ""
    readonly property var results: {
        const q = root.query.trim().toLowerCase()
        return root.entries.filter(e => e.animated === root.animatedMode
            && (q === "" || e.label.toLowerCase().includes(q)))
    }

    function indexOf(name) { return root.results.findIndex(e => e.name === name) }

    // ── What is kept ──
    // The wallpaper kept for each theme: { "kuumo-dark": "island.jpg", ... }
    property var saved: ({})

    // The wallpaper a theme should show: the one kept for it if it is still in its list,
    // otherwise its first one ("" when the theme lists none)
    function wantedFor(themeId) {
        const list = Theme.presetMap[themeId]?.wallpapers ?? []
        const keep = root.saved[themeId]
        if (keep && list.includes(keep)) return keep
        return list.length > 0 ? list[0] : ""
    }

    readonly property string savedName: root.wantedFor(root.themeId)

    // ── Showing ──
    // Puts a wallpaper on screen with awww and records it as the one showing
    function show(name, transition) {
        if (name === "") return
        Root.Config.wallpaper = name
        Quickshell.execDetached([
            "awww", "img", Root.Config.wallpaperDir + name,
            "--transition-type", transition,
            "--transition-duration", String(Root.Config.wallpaperTransitionSeconds),
            "--transition-fps", String(Root.Config.wallpaperTransitionFps)
        ])
    }

    // Shows a wallpaper without keeping it
    function preview(name) {
        if (name !== Root.Config.wallpaper) root.show(name, Root.Config.wallpaperPreviewTransition)
    }

    // Keeps a wallpaper for the active theme
    function commit(name) {
        if (name !== Root.Config.wallpaper) root.show(name, Root.Config.wallpaperTransition)
        root.saved = Object.assign({}, root.saved, { [root.themeId]: name })
        root.save()
    }

    // Puts the kept wallpaper back, if a preview is showing
    function settle() {
        const want = root.savedName
        if (want !== "" && want !== Root.Config.wallpaper)
            root.show(want, Root.Config.wallpaperPreviewTransition)
    }

    // A theme change (a preview in the theme switcher included) brings that theme's wallpaper.
    // A theme that lists no wallpapers leaves the one on screen alone.
    onThemeIdChanged: {
        const want = root.wantedFor(root.themeId)
        if (want === "" || want === Root.Config.wallpaper) return
        root.show(want, IslandState.theme
            ? Root.Config.wallpaperPreviewTransition
            : Root.Config.wallpaperTransition)
    }

    // Closing the island without choosing (Esc, a click outside, the bind again) drops the preview
    Connections {
        target: IslandState
        function onWallpaperChanged() {
            if (!IslandState.wallpaper) root.settle()
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
        path: Quickshell.statePath("wallpaper.json")
        onLoaded: root.restore(store.text())
        // Nothing kept yet: the wallpaper on screen stays
        onLoadFailed: error => {}
    }

    function restore(raw) {
        try {
            const data = JSON.parse(raw).wallpapers
            if (data && typeof data === "object") root.saved = data
        } catch (e) {
            return
        }
        const want = root.wantedFor(root.themeId)
        if (want !== "") root.show(want, Root.Config.wallpaperPreviewTransition)
    }

    function save() {
        store.setText(JSON.stringify({ wallpapers: root.saved }, null, 2))
    }

    // ── Thumbnails of animated wallpapers: the first frame, made by ffmpeg, one at a time ──
    readonly property string thumbDir: Quickshell.cachePath("wallpaper-thumbs")
    // $1 is the file, $2 the thumbnail, $3 its width; an existing thumbnail is kept
    readonly property string thumbScript:
        'mkdir -p "$(dirname "$2")" && { test -f "$2" || ffmpeg -y -loglevel error -i "$1" -frames:v 1 -vf "scale=$3:-2" "$2"; }'

    // Names whose thumbnail is ready (replaced as a whole when one is added, so bindings update)
    property var thumbsReady: ({})
    property var thumbQueue: []
    property string thumbBusy: ""

    // The thumbnail of an animated wallpaper, or "" until it is ready
    function thumbPath(name) {
        return root.thumbsReady[name] ? "file://" + root.thumbDir + "/" + name + ".png" : ""
    }

    function ensureThumb(name) {
        if (root.thumbsReady[name] || root.thumbBusy === name || root.thumbQueue.includes(name)) return
        root.thumbQueue = root.thumbQueue.concat([name])
        root.nextThumb()
    }

    function nextThumb() {
        if (thumbJob.running || root.thumbQueue.length === 0) return
        const name = root.thumbQueue[0]
        root.thumbQueue = root.thumbQueue.slice(1)
        root.thumbBusy = name
        thumbJob.command = [
            "sh", "-c", root.thumbScript, "sh",
            Root.Config.wallpaperDir + name,
            root.thumbDir + "/" + name + ".png",
            String(Root.Config.wallpaperThumbWidth)
        ]
        thumbJob.running = true
    }

    Process {
        id: thumbJob
        onExited: exitCode => {
            if (exitCode === 0)
                root.thumbsReady = Object.assign({}, root.thumbsReady, { [root.thumbBusy]: true })
            root.thumbBusy = ""
            root.nextThumb()
        }
    }
}