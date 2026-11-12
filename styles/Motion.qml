pragma Singleton
import Quickshell

Singleton {
    // Springs: response in seconds, damping 1 = no bounce
    readonly property var morph: ({ response: 0.46, damping: 0.78 })
    readonly property var digit: ({ response: 0.5, damping: 0.8 })

    // Fades are plain eases, never springs (milliseconds)
    readonly property int fadeIn: 240
    readonly property int fadeOut: 110
}