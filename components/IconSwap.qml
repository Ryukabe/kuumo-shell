import QtQuick
import "../styles"

// An icon (a Material Symbols ligature name) that swaps with a roll: the old icon
// shrinks and leaves one way while the new one grows in from the other, with a small
// bounce at the end.
Item {
    id: root

    property string name: ""
    property color color: Theme.fg
    property int pixelSize: Theme.fontSizeLg
    property real slide: 0              // distance travelled; 0 disables the motion
    property int direction: 1           // 1: the new icon rises in from below, -1: drops in from above
    property bool animated: true

    property bool ready: false
    property bool aIsFront: true
    property real t: 1                  // 0..1 progress of the swap (overshoots a little)

    width: pixelSize
    height: pixelSize

    onNameChanged: {
        if (!ready) {
            a.text = root.name
            return
        }
        const incoming = root.aIsFront ? b : a
        incoming.text = root.name
        root.aIsFront = !root.aIsFront
        if (root.animated && root.slide > 0) {
            root.t = 0
            swap.restart()
        } else {
            root.t = 1
        }
    }

    Component.onCompleted: {
        a.text = root.name
        ready = true
    }

    NumberAnimation {
        id: swap
        target: root
        property: "t"
        from: 0
        to: 1
        duration: Motion.iconSwap
        easing.type: Easing.OutBack
        easing.overshoot: Motion.iconOvershoot
    }

    Text {
        id: a
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.pixelSize
        transformOrigin: Item.Center
        opacity: root.aIsFront ? root.t : 1 - root.t
        scale: root.aIsFront
            ? Motion.iconPop + (1 - Motion.iconPop) * root.t
            : 1 - (1 - Motion.iconPop) * root.t
        y: root.aIsFront
            ? (1 - root.t) * root.direction * root.slide
            : -root.t * root.direction * root.slide
    }

    Text {
        id: b
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.pixelSize
        transformOrigin: Item.Center
        opacity: root.aIsFront ? 1 - root.t : root.t
        scale: root.aIsFront
            ? 1 - (1 - Motion.iconPop) * root.t
            : Motion.iconPop + (1 - Motion.iconPop) * root.t
        y: root.aIsFront
            ? -root.t * root.direction * root.slide
            : (1 - root.t) * root.direction * root.slide
    }
}