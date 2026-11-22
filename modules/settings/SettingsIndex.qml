pragma Singleton

import QtQuick
import Quickshell

// Everything the search can find: every page, and every setting row with a settingId.
// The rows are not listed here. The first time Settings opens, scan() builds each page once,
// off screen, and every SettingsRow reports itself through register(). The pages are then
// thrown away; only the list stays.
Singleton {
    id: root

    // Filled by scan(): { id, title, description, page, section, keywords } for each row
    property var settings: []

    // True only while scan() is building the pages; SettingsRow checks it
    property bool scanning: false
    property bool scanned: false

    // Used during a scan
    property string scanPage: ""
    property var collector: []

    // Called by a SettingsRow while a scan runs
    function register(entry) {
        if (root.collector.some(e => e.id === entry.id)) {
            console.warn("SettingsIndex: the setting id \"" + entry.id + "\" is used by more than one row")
            return
        }
        root.collector.push(Object.assign({ page: root.scanPage }, entry))
    }

    // Build every page once and collect its rows. Safe to call again: it only runs once.
    function scan() {
        if (root.scanned) return
        root.scanned = true
        root.collector = []
        root.scanning = true

        for (const page of SettingsNav.pages) {
            const component = Qt.createComponent(SettingsNav.pagesDir + page.file)
            if (component.status !== Component.Ready) {
                console.warn("SettingsIndex: could not read " + page.file + ": " + component.errorString())
                continue
            }
            root.scanPage = page.id
            const instance = component.createObject(null)
            if (instance) instance.destroy()
        }

        root.scanning = false
        root.scanPage = ""
        root.settings = root.collector
    }

    // The pages first, then the settings: { id, title, page, subtitle, keywords, icon }
    readonly property var entries: {
        const pageEntries = SettingsNav.pages.map(p => ({
            id: p.id, title: p.title, page: p.id, subtitle: "Page",
            keywords: p.keywords, icon: p.icon
        }))
        const settingEntries = root.settings.map(s => {
            const owner = SettingsNav.pages.find(p => p.id === s.page)
            return {
                id: s.id, title: s.title, page: s.page,
                subtitle: (owner ? owner.title : "") + (s.section ? " › " + s.section : ""),
                keywords: ((s.keywords ?? "") + " " + (s.description ?? "")).trim(),
                icon: owner ? owner.icon : "settings"
            }
        })
        return pageEntries.concat(settingEntries)
    }

    // How well one entry matches every word of the search; 0 means it does not match.
    // A title that starts with the word counts most, then a word inside the title, then
    // the title containing it, and a keyword counts least.
    function score(entry, words) {
        const title = entry.title.toLowerCase()
        const titleWords = title.split(/[\s-]+/)
        const keywords = (entry.keywords ?? "").toLowerCase().split(/\s+/)
        let total = 0
        for (const word of words) {
            if (title.startsWith(word)) total += 4
            else if (titleWords.some(w => w.startsWith(word))) total += 3
            else if (title.includes(word)) total += 2
            else if (keywords.some(k => k.startsWith(word))) total += 1
            else return 0
        }
        return total
    }

    // The best matches for what was typed, best first
    function search(query) {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w !== "")
        if (words.length === 0) return []
        return root.entries
            .map(entry => ({ entry: entry, score: root.score(entry, words) }))
            .filter(hit => hit.score > 0)
            .sort((a, b) => b.score - a.score)
            .slice(0, SettingsLayout.maxResults)
            .map(hit => hit.entry)
    }
}