pragma Singleton
import QtQuick
import Quickshell
import "CalcEngine.js" as Calc
import "../../state"

// What the launcher shows for the typed text: a calculator or conversion answer on top
// (when the text is one), then suggestions for finishing a conversion, then the matching
// apps.
Singleton {
    id: root

    // What is typed in the search field
    property string query: ""

    // Asks the search field to take this text (a suggestion was picked)
    signal fillRequested(string text)

    // The calculator or conversion answer for the typed text, or null
    readonly property var calc: Calc.evaluate(root.query, RatesService.rates, RatesService.fetchedAt)

    // Conversions to pick while typing a number or a unit
    readonly property var suggestions: Calc.suggest(root.query, RatesService.rates, RatesService.fetchedAt)

    // The rows of the list. Each one is { kind: "calc" | "suggest" | "app", name, sub, icon, entry, copy, fill }.
    readonly property var results: root.build(root.query, root.calc, root.suggestions)

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
            rows.push({ kind: "calc", name: answer.title, sub: answer.sub, copy: answer.copy })
        for (const hint of hints)
            rows.push({ kind: "suggest", name: hint.title, sub: hint.sub, fill: hint.fill })
        for (const app of root.search(text))
            rows.push({ kind: "app", name: app.name, sub: "", icon: app.icon, entry: app })
        return rows
    }

    // Enter or a click on a row.
    // A suggestion puts its conversion into the search box and keeps the launcher open.
    // An answer is copied, an app is started, and then the island closes. An answer with
    // nothing to copy yet (rates still loading) does nothing.
    function activate(row) {
        if (row.kind === "suggest") {
            root.fillRequested(row.fill)
            return
        }
        if (row.kind === "calc") {
            if (row.copy === "") return
            Quickshell.execDetached(["wl-copy", "--", row.copy])
        } else {
            row.entry.execute()
        }
        IslandState.closeAll()
    }
}