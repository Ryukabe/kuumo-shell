pragma Singleton

import QtQuick
import Quickshell

// Everything the search can find: every page, and every setting listed below.
Singleton {
    id: root

    // One line for every setting you build, so search can find it:
    // { id: "halo", title: "Moonlight halo", page: "island", section: "Glow", keywords: "shadow light" }
    // `page` is a page id from SettingsNav; `id` is what the row compares with SettingsNav.highlight.
    readonly property var settings: [
        { id: "island-halo", title: "Moonlight halo", page: "island", section: "Glow", keywords: "shadow light moon glow" }
    ]

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
                keywords: s.keywords ?? "",
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