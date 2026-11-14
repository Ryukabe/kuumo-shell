import QtQuick
import "../styles"

// Text that slides and fades when its content changes: the old text leaves one way
// while the new text arrives from the other.
Item {
    id: root

    property string text: ""
    property color color: Theme.fg
    property int pixelSize: Theme.fontSizeMd
    property int weight: Font.Normal
    property int alignment: Text.AlignLeft
    property real slide: 0              // distance travelled; 0 disables the motion
    property int direction: 1           // 1: new text arrives from the right, -1: from the left
    property bool animated: true

    property bool ready: false
    property bool aIsFront: true
    property real t: 1                  // 0..1 progress of the swap

    FontMetrics {
        id: metrics
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
        font.weight: root.weight
    }

    implicitHeight: Math.ceil(metrics.height)

    onTextChanged: {
        if (!ready) {
            a.text = root.text
            return
        }
        const incoming = root.aIsFront ? b : a
        incoming.text = root.text
        root.aIsFront = !root.aIsFront
        if (root.animated && root.slide > 0) {
            root.t = 0
            swap.restart()
        } else {
            root.t = 1
        }
    }

    Component.onCompleted: {
        a.text = root.text
        ready = true
    }

    NumberAnimation {
        id: swap
        target: root
        property: "t"
        from: 0
        to: 1
        duration: Motion.textSwap
        easing.type: Easing.OutCubic
    }

    Text {
        id: a
        width: root.width
        color: root.color
        elide: Text.ElideRight
        horizontalAlignment: root.alignment
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        opacity: root.aIsFront ? root.t : 1 - root.t
        x: root.aIsFront ? (1 - root.t) * root.direction * root.slide
                         : -root.t * root.direction * root.slide
    }

    Text {
        id: b
        width: root.width
        color: root.color
        elide: Text.ElideRight
        horizontalAlignment: root.alignment
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        opacity: root.aIsFront ? 1 - root.t : root.t
        x: root.aIsFront ? -root.t * root.direction * root.slide
                         : (1 - root.t) * root.direction * root.slide
    }
}