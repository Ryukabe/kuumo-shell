pragma Singleton
import Quickshell

Singleton {
    property bool doNotDisturb: false
    property string powerProfile: "balanced"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string dateText: Qt.formatDateTime(clock.date, "dddd, MMMM d")
}