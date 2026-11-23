pragma Singleton
import Quickshell
import ".." as Root
import "../state"

Singleton {
    id: root

    // ── Set in Settings, Animations ──
    // 1 is the normal speed; above 1 is faster. Spring responses and animation durations are
    // divided by it. Waiting times (how long a toast stays, how long a button is held) are not.
    readonly property real speed: Math.max(0.25, Math.min(4, Root.Config.animationSpeed))
    // How much the island overshoots when it morphs: 0 is none, 1 is a lot
    readonly property real bounce: Math.max(0, Math.min(1, Root.Config.islandBounce))

    // A duration in milliseconds, shortened or stretched by the speed
    function ms(value) { return ShellState.motionReduced ? 1 : Math.max(1, Math.round(value / root.speed)) }
    // A spring: response in seconds (shortened or stretched by the speed), damping 1 = no bounce
    function spring(response, damping) { return ({ response: response / root.speed, damping: damping }) }

    // Springs
    // Damping runs from 1.0 (no bounce) down to 0.6 (a lot); the original 0.8 is a bounce of 0.5
    readonly property var morph: root.spring(0.46, 1.0 - 0.4 * root.bounce)
    readonly property var digit: root.spring(0.5, 0.8)

    // The clock's own path: no overshoot, so it isn't dragged by the island edge's bounce
    readonly property var content: root.spring(0.42, 1.0)

    // Workspace dots growing, shrinking and appearing
    readonly property var dots: root.spring(0.38, 0.85)

    // Fades are plain eases, never springs (milliseconds)
    readonly property int fadeIn: root.ms(240)
    readonly property int fadeOut: root.ms(110)
    readonly property int hoverFade: root.ms(150)

    // Extended content appears once the pill has covered this much of its width
    // travel (0..1), and is fully visible at the end value
    readonly property real revealStart: 0.5
    readonly property real revealEnd: 0.85

    // Volume / brightness OSD: how long it stays after the last change
    readonly property int osdHoldMs: 1500
    // The bar's thumb: a slightly bouncy spring, plus a push (value units per second,
    // here pixels) when the level reaches 0 or 100
    readonly property var osdFill: root.spring(0.40, 1.0 - 0.4 * Math.max(0, Math.min(1, Root.Config.osdBounce)))
    readonly property real osdEdgeKick: 200
    // The OSD icon swap: a roll with a small bounce
    readonly property int iconSwap: root.ms(340)
    readonly property real iconOvershoot: 1.4
    readonly property real iconPop: 0.55      // scale the old icon shrinks to and the new one grows from

    // Control center sliders: after you let go (or step with a key) the moon stays where you put
    // it this long (ms) before it follows the real level again, so nothing springs back
    readonly property int sliderHoldMs: 600

    // Track change in the music viewer
    readonly property int textSwap: root.ms(380)       // title and artist slide + fade
    readonly property real artDip: 0.86                // art shrinks to this scale, then springs back
    readonly property int artDipMs: root.ms(90)        // how long it stays dipped
    readonly property int skipWindow: 2000             // how long a skip direction is remembered

    // Divider glow
    readonly property int breatheMs: 3200     // one full breath
    readonly property int surgeMs: root.ms(1100)       // how long a surge takes to fade

    // Control center buttons
    readonly property int pressMs: root.ms(90)           // squish when a button is pressed or released
    readonly property real pressScale: 0.92              // how small a pressed button gets
    readonly property int searchPulseMs: root.ms(450)    // one arc lighting up while Wi-Fi is connecting

    // Power menu: how long a dangerous button must be held, and how fast its ring
    // drains back when you let go early
    readonly property int holdMs: 900
    readonly property int holdReleaseMs: root.ms(180)

    // Switchers (theme, wallpaper): the highlighted card grows with a spring, and the row
    // of cards slides to it (milliseconds)
    readonly property var cardGrow: root.spring(0.34, 1.0 - 0.3 * Math.max(0, Math.min(1, Root.Config.switcherBounce)))
    readonly property int carouselMs: root.ms(280)

    // Search pill of the switchers: grows into a field and shrinks back to a button
    readonly property var searchPill: root.spring(0.38, 0.9)

    // The Static / Animated switch: its highlight is stretched like rubber. The edge it moves
    // toward is quick and bouncy, the other edge follows slowly.
    readonly property var rubberLead: root.spring(0.16, 0.62)
    readonly property var rubberTrail: root.spring(0.38, 0.9)

    // Polkit prompt: the Authenticate button growing into the field when you start typing,
    // and the field's shake after a wrong password (a spring around its resting place,
    // kicked sideways by shakeKick, in pixels per second)
    readonly property var authButton: root.spring(0.34, 0.85)
    readonly property var shake: root.spring(0.28, 0.3)
    readonly property real shakeKick: 300

    // The old typewriter field (TypeField), kept for now
    readonly property int typeMs: 32
    readonly property int typedCharMs: 140
    readonly property int typedCharRise: 4

    // ── Text effects (components/TypingText, BackspaceText, IrisText, ClockText,
    //    PasswordText, CopyText) ──
    // Typing: the average time per typed character, how uneven the keystrokes are (0 = even,
    // 1 = very uneven), the time per deleted character, and how long a typed line stays before
    // it is deleted (ms)
    readonly property int typingSpeed: 60
    readonly property real typingJitter: 0.5
    readonly property int typingDeleteSpeed: 30
    readonly property int typingPause: 1800
    // Backspace: the time per deleted character (ms)
    readonly property int backspaceSpeed: 40
    // The typing caret: one full blink while the typing waits (ms)
    readonly property int caretBlinkMs: 1000
    // Iris: one character opening, the time between characters, and between words (ms)
    readonly property int irisMs: root.ms(600)
    readonly property int irisStagger: root.ms(60)
    readonly property int irisWordStagger: root.ms(180)
    // Clock: a digit rising into its window, one pulse of the separators (ms), and how dim a
    // separator gets at the bottom of a pulse (0..1)
    readonly property int clockDigitMs: root.ms(400)
    readonly property int clockPulseMs: 1000
    readonly property real clockPulseDim: 0.35
    // Password: the time between one character turning from a dot into its letter and the
    // next, and how long one turn takes (ms)
    readonly property int passwordStagger: root.ms(30)
    readonly property int passwordMs: root.ms(220)
    // Copy: how long "Copied" stays before the content comes back, and the slide between them (ms)
    readonly property int copyResetMs: 2000
    readonly property int copySlideMs: root.ms(280)
}