import QtQuick
import QtQuick.Shapes
import "../../styles"

// A round control-center button drawn as a moon: a dark new moon when off, a bright
// full moon with moonlight when on. It squishes when pressed. The label sits underneath
// and can be tappable too (for example to open a list).
// Put the icon inside the button; it is centered on the moon.
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout
    property bool lit: false             // on = full moon, off = new moon
    property string label: ""
    property bool labelTappable: false   // the label reacts to hover and taps

    // Whatever is placed inside the button ends up here, centered on the moon
    default property alias icon: iconHolder.data

    // The color an icon should use: dark on the bright moon, light on the dark one
    readonly property color iconColor: Qt.tint(Theme.fg, Qt.alpha(Theme.bg, litFade))

    signal clicked()        // the moon was tapped
    signal labelClicked()   // the label was tapped

    height: layout.btnSize + layout.labelGap + labelText.implicitHeight

    // 0 (new moon) .. 1 (full moon), eased
    property real litFade: lit ? 1 : 0
    Behavior on litFade {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    // 0..1, how much the label is highlighted by the pointer
    property real labelHover: labelTappable && labelArea.containsMouse ? 1 : 0
    Behavior on labelHover {
        NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
    }

    // ── The moon: everything in here squishes when pressed ──
    Item {
        id: face
        width: root.layout.btnSize
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        scale: area.pressed ? Motion.pressScale : 1
        Behavior on scale {
            NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
        }

        // Moonlight around the moon, only while on
        Shape {
            id: glow
            readonly property real r: root.layout.btnSize / 2 + root.layout.btnGlowReach
            anchors.centerIn: parent
            width: 2 * r
            height: 2 * r
            opacity: root.litFade

            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: glow.r
                    centerY: glow.r
                    centerRadius: glow.r
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0;                   color: Qt.alpha(Theme.accent, Theme.glowPeak) }
                    GradientStop { position: Theme.glowFalloffAt; color: Qt.alpha(Theme.accent, Theme.glowPeak * Theme.glowFalloff) }
                    GradientStop { position: 1;                   color: Qt.alpha(Theme.accent, 0) }
                }
                startX: 0; startY: 0
                PathLine { x: glow.width; y: 0 }
                PathLine { x: glow.width; y: glow.height }
                PathLine { x: 0; y: glow.height }
                PathLine { x: 0; y: 0 }
            }
        }

        // The moon itself
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.tint(Theme.elevatedBg, Qt.alpha(Theme.accent, root.litFade))
            border.width: root.layout.btnBorder
            border.color: Qt.tint(Theme.border, Qt.alpha(Theme.accent, root.litFade))
        }

        // Where the icon goes
        Item {
            id: iconHolder
            anchors.fill: parent
        }
    }

    // ── The label ──
    Text {
        id: labelText
        anchors.top: face.bottom
        anchors.topMargin: root.layout.labelGap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.label
        color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, Math.max(root.litFade, root.labelHover)))
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
    }

    // ── Input ──
    // Tap the moon
    MouseArea {
        id: area
        x: face.x
        width: face.width
        height: face.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // Tap the label: a little bigger than the text so it is easy to hit
    MouseArea {
        id: labelArea
        anchors.fill: labelText
        anchors.margins: -root.layout.labelGap
        enabled: root.labelTappable
        hoverEnabled: true
        cursorShape: root.labelTappable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.labelClicked()
    }
}