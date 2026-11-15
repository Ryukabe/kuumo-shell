import QtQuick
import QtQuick.Shapes
import "../../components"
import "../../styles"
import "../../state"
import "../network"
import "../osd"

// The content of the control center. Two pages:
//   main: a row of round moon buttons (Wi-Fi for now) above the volume and brightness sliders
//   wifi: the list of Wi-Fi networks (opened by tapping the name under the Wi-Fi button)
// Island.qml places it and drives `reveal`; later stages add more buttons to the row.
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout
    // 0..1, how far the control content has appeared (from Island.qml)
    required property real reveal

    width: layout.w - 2 * layout.padX
    height: layout.h - layout.contentTop - layout.contentBottom
    opacity: reveal
    visible: reveal > 0
    // Only takes input once it is mostly visible
    enabled: reveal > 0.5

    // ── Pages ──
    property string page: "main"    // "main" | "wifi"

    // 0 (main page) .. 1 (Wi-Fi page), eased; the pages fade and slide a little
    property real pageFade: page === "wifi" ? 1 : 0
    Behavior on pageFade {
        NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
    }

    function openWifi() {
        page = "wifi"
        WifiService.openList()
    }

    function backToMain() {
        page = "main"
        WifiService.closeList()
    }

    // Closing the control center always brings it back to the main page next time
    Connections {
        target: IslandState
        function onControlChanged() {
            if (!IslandState.control && root.page !== "main") root.backToMain()
        }
    }

    // ── Main page ──
    Item {
        width: parent.width
        height: content.implicitHeight
        opacity: 1 - root.pageFade
        x: -root.layout.pageSlide * root.pageFade
        visible: opacity > 0
        enabled: root.page === "main"

        Column {
            id: content
            spacing: root.layout.sectionGap

            // ── Buttons: one slot each, side by side ──
            Row {
                MoonButton {
                    id: wifiButton
                    layout: root.layout
                    width: root.width / root.layout.tileSlots
                    lit: WifiService.radioOn
                    label: WifiService.statusText
                    labelTappable: true
                    onClicked: WifiService.toggle()
                    onLabelClicked: root.openWifi()

                    WifiIcon {
                        anchors.centerIn: parent
                        size: root.layout.tileIconSize
                        color: wifiButton.iconColor
                        active: WifiService.radioOn
                        level: WifiService.level
                        searching: WifiService.radioOn && WifiService.connecting
                        wired: WifiService.wired
                    }
                }
            }

            // ── Sliders ──
            Column {
                spacing: root.layout.rowGap

                SliderRow {
                    layout: root.layout
                    width: root.width
                    iconName: OsdService.volumeIcon
                    level: OsdService.volumeLevel
                    lit: !OsdService.muted
                    iconTappable: true
                    onIconClicked: OsdService.toggleMute()
                    onMoved: value => OsdService.setVolume(value)
                }

                SliderRow {
                    layout: root.layout
                    width: root.width
                    iconName: OsdService.brightnessIcon
                    level: OsdService.brightness
                    onMoved: value => OsdService.setBrightness(value)
                }
            }
        }
    }

    // ── Wi-Fi list page ──
    WifiPage {
        layout: root.layout
        width: parent.width
        height: parent.height
        opacity: root.pageFade
        x: root.layout.pageSlide * (1 - root.pageFade)
        visible: opacity > 0
        enabled: root.page === "wifi"
        onBack: root.backToMain()
    }

    // One slider line: icon on the left, bar with a moon on its fill, percentage on the right.
    // It only shows a level and reports where the user dragged or tapped; it never sets anything itself.
    component SliderRow: Item {
        id: row

        // The control layout block (sizes)
        required property var layout
        // Icon ligature name, e.g. "volume_up"
        required property string iconName
        // The real level from the service, 0..1
        required property real level
        // False turns the bar's light off (e.g. muted)
        property bool lit: true
        // True makes the icon tappable (e.g. to mute)
        property bool iconTappable: false

        // The user dragged to a new level (0..1)
        signal moved(real value)
        // The user tapped the icon
        signal iconClicked()

        height: layout.rowH

        // ── Dragging ──
        // While the pointer is down the moon follows it directly; otherwise it follows
        // the real level, so changes made elsewhere (keys, other apps) show up too.
        readonly property bool dragging: pointer.pressed
        property real dragLevel: 0
        readonly property real shownLevel: dragging ? dragLevel : level

        // Which way the last change went (1 up, -1 down); the icon rolls that way
        property int iconDirection: 1

        // ── Geometry ──
        readonly property real trackX: layout.iconSize + layout.iconGap
        readonly property real trackW: width - trackX - layout.pctGap - layout.pctW
        // The moon travels the track, half a moon in from each end
        readonly property real travel: trackW - layout.dotSize
        readonly property real moonX: moonSpring.value
        // The moon may poke past the ends of the track while it bounces; the fill may not
        readonly property real fillW: Math.max(0, Math.min(trackW, moonX))

        // The bar's light, fading out while `lit` is false
        property real litFade: lit ? 1 : 0
        Behavior on litFade {
            NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
        }

        // The moon follows the level on the same spring as the OSD. While dragging it
        // is not animated, so it stays under the pointer.
        Spring {
            id: moonSpring
            target: row.layout.dotSize / 2 + row.shownLevel * row.travel
            response: Motion.osdFill.response
            dampingFraction: Motion.osdFill.damping
            animated: !ShellState.motionReduced && !row.dragging
        }

        Component.onCompleted: moonSpring.snap()

        // ── Parts, left to right ──
        IconSwap {
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            name: row.iconName
            color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, row.litFade))
            pixelSize: row.layout.iconSize
            slide: row.layout.iconSize / 2
            direction: row.iconDirection
            animated: !ShellState.motionReduced
        }

        // The track
        Rectangle {
            id: track
            x: row.trackX
            width: row.trackW
            height: row.layout.barH
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.border
        }

        // The lit part of the bar
        Rectangle {
            x: row.trackX
            width: row.fillW
            height: track.height
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent
            opacity: row.litFade
        }

        // Moonlight around the leading edge
        Shape {
            id: glow
            readonly property real r: row.layout.glowReach
            x: row.trackX + row.moonX - r
            y: (row.height - 2 * r) / 2
            width: 2 * r
            height: 2 * r
            opacity: row.litFade

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
            x: row.trackX + row.moonX - width / 2
            width: row.layout.dotSize
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent
            opacity: row.litFade
        }

        // The percentage
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: row.layout.pctW
            horizontalAlignment: Text.AlignRight
            text: Math.round(row.shownLevel * 100) + "%"
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeSm
        }

        // ── Input ──
        // Tap the icon (only when `iconTappable`)
        MouseArea {
            x: 0
            width: row.trackX
            height: row.height
            enabled: row.iconTappable
            cursorShape: row.iconTappable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                row.iconDirection = row.lit ? -1 : 1    // muting rolls the icon down, unmuting up
                row.iconClicked()
            }
        }

        // Press or drag anywhere on the track row to set the level
        MouseArea {
            id: pointer
            x: row.trackX
            width: row.trackW
            height: row.height
            cursorShape: Qt.PointingHandCursor

            // Turns the pointer position into a level and reports it
            function updateFromPointer() {
                const value = Math.max(0, Math.min(1, (mouseX - row.layout.dotSize / 2) / row.travel))
                row.iconDirection = value >= row.shownLevel ? 1 : -1
                row.dragLevel = value
                moonSpring.snap()
                row.moved(value)
            }

            onPressed: {
                row.dragLevel = row.level   // start from the real level, so the direction is right
                updateFromPointer()
            }
            onPositionChanged: if (pressed) updateFromPointer()
        }
    }
}