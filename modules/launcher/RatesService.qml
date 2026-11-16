pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Exchange rates for the launcher's currency conversions. Fetched when the shell starts
// and then every refreshMs. The last answer is kept in a cache file, so conversions still
// work offline.
Singleton {
    id: root

    // Free open endpoint, no key. Rates are per 1 USD. It updates once a day, and
    // exchangerate-api.com asks for credit when you use it.
    readonly property string url: "https://open.er-api.com/v6/latest/USD"
    readonly property int refreshMs: 3600000

    // Currency code → units per 1 USD ({} until the first load)
    property var rates: ({})
    // When the rates were fetched, in ms since 1970 (0 = never)
    property real fetchedAt: 0

    // The cache file. A missing file on the first run is normal, so no error is printed.
    FileView {
        id: cache
        path: Quickshell.cachePath("exchange-rates.json")
        printErrors: false
        onLoaded: root.readCache(text())
    }

    // Use the cached rates, unless a fetch has already given newer ones
    function readCache(raw) {
        try {
            const data = JSON.parse(raw)
            if (data.rates && data.fetchedAt > root.fetchedAt) {
                root.rates = data.rates
                root.fetchedAt = data.fetchedAt
            }
        } catch (e) {
            // A damaged cache is ignored; the next fetch replaces it
        }
    }

    function fetch() {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
            try {
                const data = JSON.parse(xhr.responseText)
                if (data.result !== "success" || !data.rates) return
                root.rates = data.rates
                root.fetchedAt = Date.now()
                cache.setText(JSON.stringify({ rates: data.rates, fetchedAt: root.fetchedAt }))
            } catch (e) {
                // A bad answer keeps the rates we already have
            }
        }
        xhr.open("GET", root.url)
        xhr.send()
    }

    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }
}