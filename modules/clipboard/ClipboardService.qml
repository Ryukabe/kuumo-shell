pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root

// The clipboard history for the clipboard island.
// The history itself is kept by cliphist (text and pictures). This service starts the
// watchers that feed it, reads the list, and does the actions: copy back, delete, pin.
// It keeps only two things of its own, in state/clipboard.json: which items are pinned,
// and when each item was first seen (cliphist does not store times).
Singleton {
    id: root

    // What is typed in the search field
    property string query: ""

    // Every item cliphist has, newest first:
    // { id, preview, key, isImage, size, format, dims }
    property var items: []

    // Pinned items, by their preview text. Copying the same thing again gives it a new id
    // in cliphist, but the same preview, so the pin stays.
    property var pins: []

    // id → when the shell first saw the item (ms since 1970). 0 means it was already there.
    property var seen: ({})

    // What the list shows: pinned items first, then the rest, both newest first
    readonly property var rows: root.build(root.items, root.query, root.pins, root.seen)

    // "now", refreshed now and then so that "5m ago" stays right while the island is open
    // (these two numbers could move into Config.qml)
    readonly property int tickMs: 30000
    readonly property int refreshDelayMs: 80
    property real now: Date.now()

    Timer {
        interval: root.tickMs
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    // ── Small jobs ──
    // Runs a command in the background and calls done() when it ends
    Component {
        id: jobTemplate
        Process {
            property var done: null
            Component.onCompleted: running = true
            onExited: (exitCode) => {
                if (done) done(exitCode)
                destroy()
            }
        }
    }
    
    function run(args, done) {
        jobTemplate.createObject(root, { command: args, done: done })
    }

    // ── Starting up ──
    // First the saved pins and times are read, then old picture files are cleared away
    // (they are made again when needed), and only then the watchers and the list start.
    property bool started: false
    property bool ready: false

    function begin() {
        if (root.started) return
        root.started = true
        root.run(["rm", "-rf", root.cacheDir], function () {
            root.ready = true
            root.refresh()
        })
    }

    FileView {
        id: store
        path: Quickshell.shellPath("state/clipboard.json")
        printErrors: false

        // With no file yet (or one that cannot be read) there are no pins and no times
        onLoaded: {
            root.readState(store.text())
            root.begin()
        }
        onLoadFailed: root.begin()
    }

    function readState(raw) {
        try {
            const data = JSON.parse(raw)
            if (Array.isArray(data.pins)) root.pins = data.pins
            if (data.seen && typeof data.seen === "object") root.seen = data.seen
        } catch (error) {
            // A damaged file is ignored and written again later
        }
    }

    function save() {
        store.setText(JSON.stringify({ pins: root.pins, seen: root.seen }))
    }

    // ── Watching and reading ──
    // These two keep cliphist filled: every time something is copied, it is stored, and the
    // line "stored" tells us to read the list again.
    Process {
        running: root.ready
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "cliphist store && echo stored"]
        stdout: SplitParser { onRead: root.refresh() }
    }

    Process {
        running: root.ready
        command: ["wl-paste", "--type", "image", "--watch", "sh", "-c", "cliphist store && echo stored"]
        stdout: SplitParser { onRead: root.refresh() }
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
    }

    // Read the list again soon. Several changes close together become one read.
    function refresh() { refreshTimer.restart() }

    Timer {
        id: refreshTimer
        interval: root.refreshDelayMs
        onTriggered: {
            if (!root.ready) return
            if (lister.running) refreshTimer.restart()
            else lister.running = true
        }
    }

    // First read after start: the items already there get time 0 (unknown). Items that show
    // up later get the time they showed up.
    property bool listed: false

    function parseList(raw) {
        const list = []
        for (const line of raw.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab <= 0) continue
            const id = line.slice(0, tab)
            const preview = line.slice(tab + 1)
            // A picture shows up as "[[ binary data 12 KiB png 800x600 ]]"
            const image = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]\s*$/)
            list.push({
                id: id,
                preview: preview,
                key: preview,
                isImage: image !== null,
                size: image ? image[1] : "",
                format: image ? image[2] : "",
                dims: image ? image[3] : ""
            })
        }

        // Keep the time of every item that is still there, and give new ones theirs
        const next = {}
        let changed = list.length !== Object.keys(root.seen).length
        for (const item of list) {
            if (root.seen[item.id] !== undefined) {
                next[item.id] = root.seen[item.id]
            } else {
                next[item.id] = root.listed ? Date.now() : 0
                changed = true
            }
        }

        root.items = list
        root.listed = true
        if (changed) {
            root.seen = next
            root.save()
        }
    }

    // ── The rows ──
    function build(items, query, pinned, times) {
        const q = query.trim().toLowerCase()
        const rows = items
            .filter(item => q === "" || item.preview.toLowerCase().includes(q))
            .map(item => Object.assign({}, item, {
                pinned: pinned.includes(item.key),
                time: times[item.id] ?? 0
            }))
        return rows.filter(r => r.pinned).concat(rows.filter(r => !r.pinned))
    }

    function ageText(time, current) {
        if (time <= 0) return ""
        const mins = Math.floor((current - time) / 60000)
        if (mins < 1) return "just now"
        if (mins < 60) return mins + "m ago"
        const hours = Math.floor(mins / 60)
        if (hours < 48) return hours + "h ago"
        return Math.floor(hours / 24) + "d ago"
    }

    // The small line under a row: the size of a picture, and how long ago it was copied
    function detail(item, current) {
        const parts = []
        if (item.isImage && item.size !== "") parts.push(item.size)
        const age = root.ageText(item.time, current)
        if (age !== "") parts.push(age)
        return parts.join(" · ")
    }

    // ── Pictures ──
    // A picture is decoded to a file once, so the row can show it as a small square.
    readonly property string cacheDir: Quickshell.cachePath("clipboard")
    property var thumbs: ({})       // id → "requested" or "ready"
    property int thumbVersion: 0    // counts finished pictures, so rows notice

    function ensureThumb(id) {
        if (root.thumbs[id] !== undefined) return
        root.thumbs[id] = "requested"
        root.run(
            ["sh", "-c",
             'mkdir -p "$2" && printf "%s" "$1" | cliphist decode > "$2/$1" && [ -s "$2/$1" ] || { rm -f "$2/$1"; exit 1; }',
             "sh", id, root.cacheDir],
            function (code) {
                root.thumbs[id] = code === 0 ? "ready" : "failed"
                root.thumbVersion += 1
            })
    }

    // The file of a picture, or "" while it is not ready
    function thumbPath(id) {
        return root.thumbVersion >= 0 && root.thumbs[id] === "ready" ? root.cacheDir + "/" + id : ""
    }
    
    // ── Pasting ──
    // Types Ctrl+V (Ctrl+Shift+V in a terminal) into the window that has the keyboard. It
    // runs after the island has closed: the shell gives the keyboard back, and the script
    // waits a moment for that. Needs wtype.
    readonly property real pasteDelaySeconds: 0.15
    readonly property string pasteScript: [
        'sleep "$1"',
        "cls=$(hyprctl activewindow | sed -n 's/^[[:space:]]*class: //p' | tr 'A-Z' 'a-z')",
        'case "$cls" in',
        "  kitty|foot|footclient|alacritty|konsole|org.kde.konsole|xterm|st|st-256color|terminator|tilix|xfce4-terminal|gnome-terminal-server|org.gnome.terminal|org.wezfurlong.wezterm|com.mitchellh.ghostty)",
        "    wtype -M ctrl -M shift -k v -m shift -m ctrl ;;",
        "  *)",
        "    wtype -M ctrl -k v -m ctrl ;;",
        "esac"
    ].join("\n")

    function pasteIntoPreviousWindow() {
        Quickshell.execDetached(["sh", "-c", root.pasteScript, "sh", String(root.pasteDelaySeconds)])
    }

    // ── Actions ──
    // Put the item back on the clipboard
    function copy(item) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", item.id])
    }

    // Remove the item from the history (and its pin), then read the list again
    function remove(item) {
        root.pins = root.pins.filter(k => k !== item.key)
        root.save()
        root.run(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", item.id], root.refresh)
    }

    function togglePin(item) {
        root.pins = item.pinned
            ? root.pins.filter(k => k !== item.key)
            : root.pins.concat([item.key])
        root.save()
    }
}