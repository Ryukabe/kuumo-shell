pragma Singleton
import Quickshell
import ".." as Root

Singleton {
    property string activePopup: ""
    property bool lockscreenActive: false
    property bool barVisible: true
    // Animations off: springs jump to their target and fades are instant (Settings, Animations)
    property bool motionReduced: Root.Config.reduceMotion
}