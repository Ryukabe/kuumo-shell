pragma Singleton

import QtQuick
import Quickshell
import "../.." as Root
import "../settings"
import "CalcEngine.js" as Calc
import "EmojiData.js" as Emoji
import "../../state"

// What the launcher shows for the typed text.
// Normally: a calculator or conversion answer on top (when the text is one), then
// suggestions for finishing a conversion, then the matching apps.
// In command mode (a ">" typed first): the commands, filtered by the typed text.
// When a command is open (Enter on it): that command's own view.
Singleton {
    id: root

    // What is typed in the search field
    property string query: ""

    // Command mode: the list shows commands instead of apps. The view turns it on when
    // a ">" is typed first (and takes the ">" out of the field), and off with Backspace on
    // an empty field.
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
        : root.commandMode ? "Search commands" : "Search apps or type > for commands"

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

    // The rows of the list. Each one is { kind: "calc" | "suggest" | "app" | "command" | "note" | "emoji" | "setting",
    // name, sub, symbol (icon-font name, not for apps), icon (an app's icon), entry, copy, fill,
    // command, char (an emoji), setting (a SettingsIndex entry) }.
    readonly property var results: root.activeCommand
        ? root.buildOpen(root.activeCommand, root.query)
        : root.commandMode
            ? root.buildCommands(root.query)
            : root.build(root.query, root.calc, root.suggestions)

    // Closing the launcher also leaves command mode and closes the command that was open.
    // A request for the commands (SUPER + ALT + Space) opens them, or closes the launcher
    // when they are already showing.
    // Closing the launcher also leaves command mode and closes the command that was open.
    // A request for the commands or for one command (keybinds) opens it, or closes the
    // launcher when it is already showing.
    Connections {
        target: IslandState
        function onLauncherChanged() {
            if (!IslandState.launcher) {
                root.activeCommand = null
                root.commandMode = false
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
        return apps
            .map(a => ({ entry: a, s: root.score(a, q) }))
            .filter(m => m.s >= 0)
            .sort((a, b) => a.s - b.s || a.entry.name.localeCompare(b.entry.name))
            .map(m => m.entry)
    }

    function build(text, answer, hints) {
        const rows = []
        if (answer)
            rows.push({ kind: "calc", name: answer.title, sub: answer.sub, symbol: "calculate", copy: answer.copy })
        for (const hint of hints)
            rows.push({ kind: "suggest", name: hint.title, sub: hint.sub, symbol: "swap_horiz", fill: hint.fill })
        for (const app of root.search(text))
            rows.push({ kind: "app", name: app.name, sub: "", icon: app.icon, entry: app })
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
        return found.map(e => ({
            kind: "setting",
            name: e.title,
            sub: e.subtitle,
            symbol: e.icon,
            setting: e
        }))
    }

    // The current value of a setting, as the text shown on its row
    function settingValue(entry) {
        const c = entry.control
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

    // Enter or a click on a row.
    // A suggestion puts its conversion into the search box and keeps the launcher open.
    // A setting changes and keeps the launcher open.
    // A command that does its own thing (like opening the clipboard) runs and handles the
    // island itself; any other command opens its view here.
    // An answer or an emoji is copied, an app is started, and then the island closes.
    // An answer with nothing to copy yet (rates still loading) does nothing, and neither
    // does a note.
    function activate(row) {
        if (row.kind === "suggest") {
            root.fillRequested(row.fill)
            return
        }
        if (row.kind === "setting") {
            root.flipSetting(row.setting)
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
        } else {
            row.entry.execute()
        }
        IslandState.closeAll()
    }
}