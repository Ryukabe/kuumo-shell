import QtQuick
import QtQuick.Shapes
import "../../styles"

// A round power-menu button drawn like the control center's moon. A tap button lights
// up while it is selected and fires on release. A hold button fills like a moon
// while you hold it, with a red ring growing around it, and fires when the ring closes.
// Letting go early drains it back. The pointer and the keyboard both select a button.
Item {
    id: root

    // The power layout block from Island.qml
    required property var layout
    property string label: ""
    property string iconName: ""
    property bool hold: false       // must be held instead of tapped
    property bool ready: true       // false = dimmed, does nothing
    // The button the pointer or the keyboard is on
    property bool selected: false
    // How lit a selected hold button is before you start holding it (0..1)
    property real holdSelectedLevel: 0.35

    signal activated()
    // The pointer came onto the button
    signal hovered()

    // 0..1, how far the hold has got
    property real progress: 0

    // 0..1, the moon's brightness: the hold or the selection
    property real hoverFade: selected ? (hold ? holdSelectedLevel : 1) : 0
    Behavior on hoverFade {
        NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
    }
    readonly property real litFade: Math.max(hoverFade, progress)

    // The color an icon should use: dark on the bright moon, light on the dark one
    readonly property color iconColor: Qt.tint(Theme.fg, Qt.alpha(Theme.bg, litFade))

    height: layout.btnSize + layout.labelGap + labelText.implicitHeight
    opacity: ready ? 1 : Theme.dimOpacity

    // ── Hold ──
    NumberAnimation {
        id: fill
        target: root
        property: "progress"
        to: 1
        duration: Motion.holdMs
        easing.type: Easing.Linear
        // The ring closed: fire, then reset so the button is ready again
        onRunningChanged: {
            if (!running && root.progress >= 1) {
                root.activated()
                root.progress = 0
            }
        }
    }

    NumberAnimation {
        id: drain
        target: root
        property: "progress"
        to: 0
        duration: Motion.holdReleaseMs
        easing.type: Easing.OutCubic
    }

    // Start filling the ring (the pointer pressing, or a key held down)
    function startHold() {
        if (!root.ready || !root.hold) return
        drain.stop()
        fill.restart()
    }

    function cancelHold() {
        if (!fill.running) return
        fill.stop()
        drain.restart()
    }

    // ── The moon ──
    Item {
        id: face
        width: root.layout.btnSize
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        scale: area.pressed ? Motion.pressScale : 1
        Behavior on scale {
            NumberAnimation { duration: Motion.pressMs; easing.type: Easing.OutCubic }
        }

        // Moonlight around the moon, as bright as the moon is lit
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

        // The hold ring: starts at the top and grows clockwise
        Shape {
            anchors.fill: parent
            visible: root.progress > 0

            ShapePath {
                strokeWidth: root.layout.holdRingW
                strokeColor: Theme.red
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: face.width / 2
                    centerY: face.height / 2
                    radiusX: face.width / 2 - root.layout.holdRingW / 2
                    radiusY: face.height / 2 - root.layout.holdRingW / 2
                    startAngle: -90
                    sweepAngle: 360 * root.progress
                }
            }
        }

        // The icon
        Text {
            anchors.centerIn: parent
            text: root.iconName
            color: root.iconColor
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.tileIconSize
        }
    }

    // ── The label: turns red while held ──
    Text {
        id: labelText
        anchors.top: face.bottom
        anchors.topMargin: root.layout.labelGap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.label
        color: Qt.tint(Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, root.litFade)), Qt.alpha(Theme.red, root.progress))
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
    }

    // ── Input ──
    MouseArea {
        id: area
        x: face.x
        width: face.width
        height: face.height
        enabled: root.ready
        hoverEnabled: true
        cursorShape: root.ready ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: root.startHold()
        onReleased: root.cancelHold()
        onCanceled: root.cancelHold()
        onContainsMouseChanged: {
            if (containsMouse) root.hovered()
            // Sliding off the button while held cancels too
            else root.cancelHold()
        }
        onClicked: if (!root.hold) root.activated()
    }
}