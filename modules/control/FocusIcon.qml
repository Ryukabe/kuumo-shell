import QtQuick
import "../../styles"

// The Focus icon: a crescent moon, and a cloud that slides over it while Focus is on.
Item {
    id: root

    property int size: Theme.fontSizeLg
    property color color: Theme.fg
    property bool active: false    // Focus on: the cloud is over the moon

    width: size
    height: size

    // ── Drawing proportions (fractions of `size`) ──
    readonly property real cloudSize: 0.75     // the cloud's size
    readonly property real cloudRestX: 0.18    // where the cloud ends up, right of center
    readonly property real cloudRestY: 0.2     // and below center
    readonly property real cloudSlide: 0.9     // how far to the right it starts

    // 0 (cloud away) .. 1 (cloud over the moon), with a small bounce at the end
    property real cover: active ? 1 : 0
    Behavior on cover {
        NumberAnimation {
            duration: Motion.iconSwap
            easing.type: Easing.OutBack
            easing.overshoot: Motion.iconOvershoot
        }
    }

    // The moon
    Text {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "dark_mode"
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.size
    }

    // The cloud
    Text {
        width: root.size
        height: root.size
        x: root.size * (root.cloudRestX + (1 - root.cover) * root.cloudSlide)
        y: root.size * root.cloudRestY
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "cloud"
        color: root.color
        font.family: Theme.fontIcon
        font.pixelSize: root.size * root.cloudSize
        opacity: Math.max(0, Math.min(1, root.cover))
    }
}