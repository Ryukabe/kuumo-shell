pragma Singleton
import Quickshell

Singleton {
    // Springs: response in seconds, damping 1 = no bounce
    readonly property var morph: ({ response: 0.46, damping: 0.8 })
    readonly property var digit: ({ response: 0.5, damping: 0.8 })
    
    // The clock's own path: no overshoot, so it isn't dragged by the island edge's bounce
    readonly property var content: ({ response: 0.42, damping: 1.0 })

    // Fades are plain eases, never springs (milliseconds)
    readonly property int fadeIn: 240
    readonly property int fadeOut: 110
}