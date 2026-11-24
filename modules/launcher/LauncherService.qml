pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../.." as Root
import "../settings"
import "CalcEngine.js" as Calc
import "EmojiData.js" as Emoji
import "../../state"

// What the launcher shows for the typed text.
// Normally (a universal search): a calculator or conversion answer on top (when the text is
// one), suggestions for finishing a conversion, then groups of results (apps, commands,
// settings, files) under small headers, best group first, and a web search row at the end.
// Each source can be turned off in Settings. Empty text lists the apps.
// In command mode (a ">" typed first): the commands, filtered by the typed text.
// When a command is open (Enter on it): that command's own view.
Singleton {
    id: root

    // ── Tuning ──
    readonly property int filesMinChars: 2       // the disk is searched from this many characters
    readonly property int filesDebounceMs: 150   // wait this long after the last key before searching
    readonly property int filesFetch: 150        // fd stops after this many files; the best are shown
    readonly property int filesTimeoutS: 3       // a search that takes longer is stopped (what it found is kept)

    // What is typed in the search field
    property string query: ""

    // Command mode: the list shows commands instead of results. The view turns it on when
    // a ">" is typed first (and takes the ">" out of the field), and off with Backspace on
    // an empty field (when that is on in Settings).
    property bool commandMode: false

    // The command that is open, or null while none is
    property var activeCommand: null

    // The emoji picker shows its rows as a grid, everything else as a list
    readonly property bool gridView: root.activeCommand !== null && root.activeCommand.id === "emoji"

    // The settings command lists settings you can change right here
    readonly property bool settingsView: root.activeCommand !== null && root.activeCommand.id === "settings"

    // The icon at the start of the search field and the hint of the empty field, for the
    // mode the launcher is in
    readonly property string fieldSymbol: root.activeCommand
        ? root.activeCommand.icon
        : root.commandMode ? "terminal" : "search"
    readonly property string fieldHint: root.activeCommand
        ? root.activeCommand.hint
        : root.commandMode ? "Search commands" : "Search or type > for commands"

    // Asks the search field to take this text (a suggestion was picked)
    signal fillRequested(string text)

    // The calculator or conversion answer for the typed text, or null
    readonly property var calc: Root.Config.launcherCalculator
        ? Calc.evaluate(root.query, RatesService.rates, RatesService.fetchedAt)
        : null

    // Conversions to pick while typing a number or a unit
    readonly property var suggestions: Root.Config.launcherSuggestions
        ? Calc.suggest(root.query, RatesService.rates, RatesService.fetchedAt)
        : []

    // The rows of the list. Each one is { kind: "calc" | "suggest" | "app" | "command" | "note" |
    // "emoji" | "setting" | "file" | "web" | "header", name, sub, symbol (icon-font name, not for
    // apps), icon (an app's icon), entry, copy, fill, command, char (an emoji), setting (a
    // SettingsIndex entry), path / dir / isDir (a file), query (a web search) }.
    readonly property var results: root.activeCommand
        ? root.buildOpen(root.activeCommand, root.query)
        : root.commandMode
            ? root.buildCommands(root.query)
            : root.build(root.query, root.calc, root.suggestions)

    // Closing the launcher also leaves command mode, closes the command that was open, and
    // forgets the files found. A request for the commands or for one command (keybinds) opens
    // it, or closes the launcher when it is already showing.
    Connections {
        target: IslandState
        function onLauncherChanged() {
            if (!IslandState.launcher) {
                root.activeCommand = null
                root.commandMode = false
                root.fileWanted = ""
                root.fileHits = []
                if (!fdProc.running) root.fileRunning = ""
            }
        }
        function onCommandRequested(id, wasOpen) {
            // The command list
            if (id === "") {
                if (wasOpen && root.commandMode && !root.activeCommand) {
                    IslandState.collapse()
                    return
                }
                root.activeCommand = null
                root.commandMode = true
                // Text typed in the apps view must not filter the commands
                if (root.query !== "") root.fillRequested("")
                return
            }

            // One command
            const cmd = root.commandById(id)
            if (!cmd || !cmd.ready) return
            if (wasOpen && root.activeCommand && root.activeCommand.id === id) {
                IslandState.collapse()
                return
            }
            // A command that does its own thing (the clipboard, ...) takes over the island
            if (CommandService.run(cmd)) return
            // The settings view needs the list of settings, which is built the first time
            if (id === "settings") SettingsIndex.scan()
            root.commandMode = true
            root.activeCommand = cmd
        }
    }

    function commandById(id) {
        return CommandService.commands.find(c => c.id === id) ?? null
    }

    function closeCommand() { root.activeCommand = null }
    function leaveCommands() { root.commandMode = false }

    // ── Files ──
    // The files found by fd for the typed text: [{ path, name, dir, isDir, depth }]
    property var fileHits: []
    // What should be searched next, and what fd is searching (or searched last)
    property string fileWanted: ""
    property string fileRunning: ""

    // A new search is wanted whenever the text changes; the settings list is built the first
    // time something is typed (it takes a moment)
    onQueryChanged: {
        const q = root.query.trim()
        if (q !== "" && Root.Config.launcherSourceSettings && !SettingsIndex.scanned) SettingsIndex.scan()

        if (Root.Config.launcherSourceFiles && !root.activeCommand && !root.commandMode && q.length >= root.filesMinChars) {
            root.fileWanted = q
            fileTimer.restart()
        } else {
            root.fileWanted = ""
            root.fileHits = []
            if (!fdProc.running) root.fileRunning = ""
        }
    }

    // fd matches the file name; several words must appear in it in the order typed
    function fdCommand(q) {
        const words = q.split(/\s+/).filter(w => w !== "")
        const pattern = words.map(w => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join(".*")
        const home = Quickshell.env("HOME")
        const where = Root.Config.launcherFilesWhere === "common"
            ? ["Documents", "Downloads", "Desktop", "Pictures", "Videos", "Music"].map(d => home + "/" + d)
            : [home]
        const cmd = ["timeout", String(root.filesTimeoutS), "fd", "--color", "never", "--max-results", String(root.filesFetch)]
        if (Root.Config.launcherFilesHidden) cmd.push("--hidden")
        cmd.push("--", pattern)
        return cmd.concat(where)
    }

    // Starts the search that is wanted, unless one is running (it starts again when that ends)
    function startFileSearch() {
        if (fdProc.running) return
        if (root.fileWanted === "" || root.fileWanted === root.fileRunning) return
        root.fileRunning = root.fileWanted
        fdProc.command = root.fdCommand(root.fileRunning)
        fdProc.running = true
    }

    // fd prints one path per line, with a "/" after a folder
    function fileSearchDone(text) {
        if (root.fileWanted === "") {
            root.fileRunning = ""
            return
        }
        const hits = []
        for (const line of text.split("\n")) {
            if (line === "") continue
            const isDir = line.endsWith("/")
            const path = isDir ? line.slice(0, -1) : line
            const slash = path.lastIndexOf("/")
            hits.push({
                path: path,
                isDir: isDir,
                name: path.slice(slash + 1),
                dir: slash > 0 ? path.slice(0, slash) : "/",
                depth: path.split("/").length
            })
        }
        root.fileHits = hits
    }

    // Does the name contain every word, in the order typed?
    function fileMatches(hit, words) {
        const name = hit.name.toLowerCase()
        let from = 0
        for (const word of words) {
            const at = name.indexOf(word, from)
            if (at < 0) return false
            from = at + word.length
        }
        return true
    }

    // How good a file match is: 0 the name starts with the first word, 1 a word of the name
    // does, 2 it is somewhere inside
    function fileRank(hit, words) {
        const name = hit.name.toLowerCase()
        if (name.startsWith(words[0])) return 0
        if (/[\s._-]/.test(name) && new RegExp("[\\s._-]" + words[0].replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).test(name)) return 1
        return 2
    }

    // A folder as it is shown: the home folder as ~
    function shortDir(dir) {
        const home = Quickshell.env("HOME")
        return home && dir.startsWith(home) ? "~" + dir.slice(home.length) : dir
    }

    Timer {
        id: fileTimer
        interval: root.filesDebounceMs
        onTriggered: root.startFileSearch()
    }

    Process {
        id: fdProc
        stdout: StdioCollector { onStreamFinished: root.fileSearchDone(text) }
        // When one search ends, the newest wanted one (if any) starts
        onRunningChanged: if (!running) fileTimer.restart()
    }

    // ── Apps ──
    // How well an app matches: lower is better, -1 is no match
    function score(entry, q) {
        const name = entry.name.toLowerCase()
        if (name.startsWith(q)) return 0
        if (name.includes(" " + q)) return 1
        if (name.includes(q)) return 2
        const extra = ((entry.genericName ?? "") + " " + (entry.keywords ?? []).join(" ")).toLowerCase()
        if (extra.includes(q)) return 3
        return -1
    }

    // Matching apps, best match first. Empty search lists every app by name.
    function search(text) {
        const q = text.trim().toLowerCase()
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (q === "")
            return apps.sort((a, b) => a.name.localeCompare(b.name))
        return root.scoredApps(q).map(m => m.entry)
    }

    // Matching apps with their score, best first (q is lower case)
    function scoredApps(q) {
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        return apps
            .map(a => ({ entry: a, s: root.score(a, q) }))
            .filter(m => m.s >= 0)
            .sort((a, b) => a.s - b.s || a.entry.name.localeCompare(b.entry.name))
    }

    function appRow(app) {
        return { kind: "app", name: app.name, sub: "", icon: app.icon, entry: app }
    }

    // ── The groups of results ──
    // Each group is { title, order, tier, rows }: tier says how good its best result is (0 the
    // name starts with what was typed .. 3 only a keyword matches); the groups with the best
    // result come first, and order breaks ties.
    function appGroup(lower, max) {
        const found = root.scoredApps(lower)
        return {
            title: "Apps", order: 0, tier: found.length > 0 ? found[0].s : 9,
            rows: found.slice(0, max).map(m => root.appRow(m.entry))
        }
    }

    function commandGroup(lower, max) {
        const found = CommandService.commands
            .filter(c => c.ready)
            .map(c => ({ cmd: c, s: CommandService.score(c, lower) }))
            .filter(m => m.s >= 0)
            .sort((a, b) => a.s - b.s)
        return {
            title: "Commands", order: 1, tier: found.length > 0 ? found[0].s : 9,
            rows: found.slice(0, max).map(m => ({
                kind: "command", name: m.cmd.name, sub: m.cmd.sub, symbol: m.cmd.icon, command: m.cmd
            }))
        }
    }

    // A row for a SettingsIndex entry (a settings page or one setting). In the universal search
    // Enter changes a toggle or a choice right there and opens anything else in the Settings window.
    function settingRow(entry, universal) {
        return {
            kind: "setting",
            name: entry.title,
            sub: entry.subtitle === "Page" ? "Settings page" : entry.subtitle,
            symbol: entry.icon,
            setting: entry,
            opensOnEnter: universal && (!entry.control || entry.control.kind === "number" || entry.control.kind === "color")
        }
    }

    function settingGroup(lower, max) {
        const words = lower.split(/\s+/).filter(w => w !== "")
        const found = SettingsIndex.search(lower)
        let tier = 9
        if (found.length > 0) {
            const best = SettingsIndex.score(found[0], words)
            const n = words.length
            tier = best >= 4 * n ? 0 : best >= 3 * n ? 1 : best >= 2 * n ? 2 : 3
        }
        return {
            title: "Settings", order: 2, tier: tier,
            rows: found.slice(0, max).map(e => root.settingRow(e, true))
        }
    }

    function fileGroup(lower, max) {
        const words = lower.split(/\s+/).filter(w => w !== "")
        const found = root.fileHits
            .filter(h => root.fileMatches(h, words))
            .map(h => ({ hit: h, rank: root.fileRank(h, words) }))
            .sort((a, b) => a.rank - b.rank || a.hit.depth - b.hit.depth || a.hit.name.length - b.hit.name.length)
        return {
            title: "Files", order: 3, tier: found.length > 0 ? found[0].rank : 9,
            rows: found.slice(0, max).map(m => ({
                kind: "file",
                name: m.hit.name,
                sub: root.shortDir(m.hit.dir),
                symbol: m.hit.isDir ? "folder" : "description",
                path: m.hit.path,
                dir: m.hit.dir,
                isDir: m.hit.isDir
            }))
        }
    }

    // ── The web ──
    function webEngine() {
        const engines = {
            duckduckgo: { label: "DuckDuckGo", url: "https://duckduckgo.com/?q=" },
            google: { label: "Google", url: "https://www.google.com/search?q=" },
            brave: { label: "Brave Search", url: "https://search.brave.com/search?q=" },
            startpage: { label: "Startpage", url: "https://www.startpage.com/do/search?q=" }
        }
        return engines[Root.Config.launcherWebEngine] ?? engines.duckduckgo
    }

    // ── Building the list ──
    function build(text, answer, hints) {
        const rows = []
        if (answer)
            rows.push({ kind: "calc", name: answer.title, sub: answer.sub, symbol: "calculate", copy: answer.copy })
        for (const hint of hints)
            rows.push({ kind: "suggest", name: hint.title, sub: hint.sub, symbol: "swap_horiz", fill: hint.fill })

        const q = text.trim()
        if (q === "") {
            if (Root.Config.launcherSourceApps)
                for (const app of root.search("")) rows.push(root.appRow(app))
            return rows
        }

        const lower = q.toLowerCase()
        const max = Root.Config.launcherGroupMax
        const groups = []
        if (Root.Config.launcherSourceApps) groups.push(root.appGroup(lower, max))
        if (Root.Config.launcherSourceCommands) groups.push(root.commandGroup(lower, max))
        if (Root.Config.launcherSourceSettings) groups.push(root.settingGroup(lower, max))
        if (Root.Config.launcherSourceFiles) groups.push(root.fileGroup(lower, max))

        const shown = groups.filter(g => g.rows.length > 0)
        shown.sort((a, b) => a.tier - b.tier || a.order - b.order)
        for (const group of shown) {
            if (Root.Config.launcherHeaders) rows.push({ kind: "header", name: group.title })
            for (const row of group.rows) rows.push(row)
        }

        if (Root.Config.launcherSourceWeb)
            rows.push({
                kind: "web", name: "Search the web for \"" + q + "\"", sub: root.webEngine().label,
                symbol: "travel_explore", query: q
            })
        return rows
    }

    // The commands that match the typed text. A command that is not connected yet says
    // so under its name.
    function buildCommands(text) {
        return CommandService.search(text).map(c => ({
            kind: "command",
            name: c.name,
            sub: c.ready ? c.sub : c.sub + " · coming soon",
            symbol: c.icon,
            command: c
        }))
    }

    // The view of an open command: the emoji for the emoji picker, the settings you can
    // change for the settings command, and until the other commands are connected, one note.
    function buildOpen(cmd, text) {
        if (cmd.id === "emoji") return Emoji.search(text)
        if (cmd.id === "settings") return root.settingRows(text)
        return [{ kind: "note", name: "Coming soon", sub: cmd.name + " is not connected yet", symbol: "hourglass_empty" }]
    }

    // ── Settings ──
    // The settings the launcher can change (not colors), matching the typed words, best
    // first. The rows do not read the setting values, so changing one does not rebuild
    // the list; the value on each row is read live by the view through settingValue().
    function settingRows(text) {
        const words = text.trim().toLowerCase().split(/\s+/).filter(w => w !== "")
        const changeable = SettingsIndex.entries.filter(e => e.control && e.control.kind !== "color")
        const found = words.length === 0
            ? changeable
            : changeable
                .map(e => ({ entry: e, s: SettingsIndex.score(e, words) }))
                .filter(m => m.s > 0)
                .sort((a, b) => b.s - a.s)
                .map(m => m.entry)
        return found.map(e => root.settingRow(e, false))
    }

    // The current value of a setting, as the text shown on its row ("" when it cannot be
    // changed here)
    function settingValue(entry) {
        const c = entry.control
        if (!c) return ""
        const v = Root.Config[c.key]
        if (c.kind === "toggle") return v ? "On" : "Off"
        if (c.kind === "number")
            return Math.round(v * c.scale * 100) / 100 + (c.unit !== "" ? " " + c.unit : "")
        if (c.kind === "choice") {
            const option = c.options.find(o => o.value === v)
            return option ? option.label : String(v)
        }
        return String(v)
    }

    // The next (direction 1) or previous (-1) option of a choice, wrapping around
    function cycleChoice(c, direction) {
        const count = c.options.length
        if (count === 0) return
        const at = c.options.findIndex(o => o.value === Root.Config[c.key])
        SettingsState.set(c.key, c.options[(at + direction + count) % count].value)
    }

    // Enter or a click: a toggle flips, a choice moves to its next option, a number does nothing
    function flipSetting(entry) {
        const c = entry.control
        if (c.kind === "toggle") SettingsState.set(c.key, !Root.Config[c.key])
        else if (c.kind === "choice") root.cycleChoice(c, 1)
    }

    // Left or right: a toggle goes off or on, a choice moves, a number takes one step
    // (five with big), kept between its ends
    function nudgeSetting(entry, direction, big) {
        const c = entry.control
        if (c.kind === "toggle") {
            SettingsState.set(c.key, direction > 0)
        } else if (c.kind === "choice") {
            root.cycleChoice(c, direction)
        } else if (c.kind === "number") {
            const amount = c.step * (big ? 5 : 1)
            const next = Math.max(c.from, Math.min(c.to, Root.Config[c.key] + direction * amount))
            SettingsState.set(c.key, Math.round(next * 1000) / 1000)
        }
    }

    // Opens a settings page (and points at the setting) in the Settings window, and closes the island
    function openInSettings(entry) {
        SettingsNav.openEntry(entry)
        SettingsNav.show()
        IslandState.closeAll()
    }

    // Enter or a click on a row (reveal is true with Ctrl held: a file is shown in its folder).
    // A suggestion puts its conversion into the search box and keeps the launcher open.
    // A setting you can change here changes and keeps the launcher open; any other setting
    // opens in the Settings window.
    // A command that does its own thing (like opening the clipboard) runs and handles the
    // island itself; any other command opens its view here.
    // An answer or an emoji is copied, a file is opened, a web search is started, an app is
    // started, and then the island closes.
    // An answer with nothing to copy yet (rates still loading) does nothing, and neither
    // does a note or a header.
    function activate(row, reveal) {
        if (row.kind === "header") return
        if (row.kind === "suggest") {
            root.fillRequested(row.fill)
            return
        }
        if (row.kind === "setting") {
            const control = row.setting.control
            if (row.opensOnEnter || !control || control.kind === "color") root.openInSettings(row.setting)
            else root.flipSetting(row.setting)
            return
        }
        if (row.kind === "command") {
            if (!CommandService.run(row.command)) {
                // The settings view needs the list of settings, which is built the first time
                if (row.command.id === "settings") SettingsIndex.scan()
                root.activeCommand = row.command
            }
            return
        }
        if (row.kind === "note") return
        if (row.kind === "calc") {
            if (row.copy === "") return
            Quickshell.execDetached(["wl-copy", "--", row.copy])
        } else if (row.kind === "emoji") {
            Quickshell.execDetached(["wl-copy", "--", row.char])
        } else if (row.kind === "file") {
            Quickshell.execDetached(["xdg-open", reveal ? row.dir : row.path])
        } else if (row.kind === "web") {
            Quickshell.execDetached(["xdg-open", root.webEngine().url + encodeURIComponent(row.query)])
        } else {
            row.entry.execute()
        }
        IslandState.closeAll()
    }
}