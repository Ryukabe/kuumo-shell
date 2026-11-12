pragma Singleton
import Quickshell

Singleton {
    // Springs: response in seconds, damping 1 = no bounce
    readonly property var morph: ({ response: 0.46, damping: 0.78 })

    // Fades are plain eases, never springs (milliseconds)
    readonly property int fadeIn: 240
    readonly property int fadeOut: 110
}