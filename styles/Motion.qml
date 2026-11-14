pragma Singleton
import Quickshell

Singleton {
    // Springs: response in seconds, damping 1 = no bounce
    readonly property var morph: ({ response: 0.46, damping: 0.8 })
    readonly property var digit: ({ response: 0.5, damping: 0.8 })

    // The clock's own path: no overshoot, so it isn't dragged by the island edge's bounce
    readonly property var content: ({ response: 0.42, damping: 1.0 })

    // Workspace dots growing, shrinking and appearing
    readonly property var dots: ({ response: 0.38, damping: 0.85 })

    // Fades are plain eases, never springs (milliseconds)
    readonly property int fadeIn: 240
    readonly property int fadeOut: 110
    readonly property int hoverFade: 150

    // Extended content appears once the pill has covered this much of its width
    // travel (0..1), and is fully visible at the end value
    readonly property real revealStart: 0.5
    readonly property real revealEnd: 0.85

    // Track change in the music viewer
    readonly property int textSwap: 380       // title and artist slide + fade
    readonly property real artDip: 0.86       // art shrinks to this scale, then springs back
    readonly property int artDipMs: 90        // how long it stays dipped
    readonly property int skipWindow: 2000    // how long a skip direction is remembered

    // Divider glow
    readonly property int breatheMs: 3200     // one full breath
    readonly property int surgeMs: 1100       // how long a surge takes to fade
}