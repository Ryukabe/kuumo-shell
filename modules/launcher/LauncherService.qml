pragma Singleton

import QtQuick
import Quickshell
import "../.." as Root
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

    // The rows of the list. Each one is { kind: "calc" | "suggest" | "app" | "command" | "note" | "emoji",
    // name, sub, symbol (icon-font name, not for apps), icon (an app's icon), entry, copy, fill,
    // command, char (an emoji) }.
    readonly property var results: root.activeCommand
        ? root.buildOpen(root.activeCommand, root.query)
        : root.commandMode
            ? root.buildCommands(root.query)
            : root.build(root.query, root.calc, root.suggestions)

    // Closing the launcher also leaves command mode and closes the command that was open
    Connections {
        target: IslandState
        function onLauncherChanged() {
            if (!IslandState.launcher) {
                root.activeCommand = null
                root.commandMode = false
            }
        }
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

    // The view of an open command: the emoji for the emoji picker, and until the other
    // commands are connected, one note.
    function buildOpen(cmd, text) {
        if (cmd.id === "emoji") return Emoji.search(text)
        return [{ kind: "note", name: "Coming soon", sub: cmd.name + " is not connected yet", symbol: "hourglass_empty" }]
    }

    // Enter or a click on a row.
    // A suggestion puts its conversion into the search box and keeps the launcher open.
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
        if (row.kind === "command") {
            if (!CommandService.run(row.command)) root.activeCommand = row.command
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