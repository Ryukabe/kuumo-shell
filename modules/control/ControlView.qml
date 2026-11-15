import QtQuick
import "../../styles"
import "../../state"
import "../display"
import "../network"
import "../notifications"
import "../osd"

// The content of the control center. Pages:
//   main:          a row of round moon buttons, the volume and brightness sliders, and the
//                  notifications card
//   wifi:          the list of Wi-Fi networks (tap the name under the Wi-Fi button)
//   nightlight:    temperature and gamma (tap the name under the Night Light button)
//   notifications: the list of notifications (tap the card at the bottom)
// Island.qml places it and drives `reveal`; later stages add more buttons to the row.
// The view starts at `pageTop`. Only the main page shows the clock, so it moves itself down.
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout
    // 0..1, how far the control content has appeared (from Island.qml)
    required property real reveal

    width: layout.w - 2 * layout.padX
    height: layout.h - layout.pageTop - layout.contentBottom
    opacity: reveal
    visible: reveal > 0
    // Only takes input once it is mostly visible
    enabled: reveal > 0.5

    // ── Pages ──
    // Island.qml reads this to hide the clock on every page except the main one
    property string page: "main"    // "main" | "wifi" | "nightlight" | "notifications"

    function openPage(name) {
        page = name
        if (name === "wifi") WifiService.openList()
        if (name === "notifications") NotificationService.markAllRead()
    }

    function backToMain() {
        if (page === "wifi") WifiService.closeList()
        page = "main"
    }

    // Closing the control center always brings it back to the main page next time
    Connections {
        target: IslandState
        function onControlChanged() {
            if (!IslandState.control && root.page !== "main") root.backToMain()
        }
    }

    // Notifications that arrive while their page is open count as read at once
    Connections {
        target: NotificationService
        function onUnreadChanged() {
            if (root.page === "notifications") NotificationService.markAllRead()
        }
    }

    // ── Main page ──
    PageFrame {
        layout: root.layout
        shown: root.page === "main"
        direction: -1
        y: root.layout.contentTop - root.layout.pageTop
        width: parent.width
        height: content.implicitHeight

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
                    onLabelClicked: root.openPage("wifi")

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

                MoonButton {
                    id: nightLightButton
                    layout: root.layout
                    width: root.width / root.layout.tileSlots
                    lit: NightLightService.enabled
                    label: NightLightService.statusText
                    labelTappable: true
                    onClicked: NightLightService.toggle()
                    onLabelClicked: root.openPage("nightlight")

                    // A crescent moon
                    Text {
                        anchors.centerIn: parent
                        text: "dark_mode"
                        color: nightLightButton.iconColor
                        font.family: Theme.fontIcon
                        font.pixelSize: root.layout.tileIconSize
                    }
                }

                MoonButton {
                    id: focusButton
                    layout: root.layout
                    width: root.width / root.layout.tileSlots
                    lit: NotificationService.focusOn
                    label: "Focus"
                    onClicked: NotificationService.toggleFocus()

                    FocusIcon {
                        anchors.centerIn: parent
                        size: root.layout.tileIconSize
                        color: focusButton.iconColor
                        active: NotificationService.focusOn
                    }
                }
            }

            // ── Sliders ──
            Column {
                spacing: root.layout.rowGap

                MoonSlider {
                    layout: root.layout
                    width: root.width
                    iconName: OsdService.volumeIcon
                    level: OsdService.volumeLevel
                    lit: !OsdService.muted
                    iconTappable: true
                    onIconClicked: OsdService.toggleMute()
                    onMoved: value => OsdService.setVolume(value)
                }

                MoonSlider {
                    layout: root.layout
                    width: root.width
                    iconName: OsdService.brightnessIcon
                    level: OsdService.brightness
                    onMoved: value => OsdService.setBrightness(value)
                }
            }

            // ── Notifications ──
            NotificationCard {
                layout: root.layout
                width: root.width
                onClicked: root.openPage("notifications")
            }
        }
    }

    // ── Wi-Fi list page ──
    PageFrame {
        layout: root.layout
        shown: root.page === "wifi"
        width: parent.width
        height: parent.height

        WifiPage {
            anchors.fill: parent
            layout: root.layout
            onBack: root.backToMain()
        }
    }

    // ── Night Light page ──
    PageFrame {
        layout: root.layout
        shown: root.page === "nightlight"
        width: parent.width
        height: parent.height

        NightLightPage {
            anchors.fill: parent
            layout: root.layout
            onBack: root.backToMain()
        }
    }

    // ── Notifications page ──
    PageFrame {
        layout: root.layout
        shown: root.page === "notifications"
        width: parent.width
        height: parent.height

        NotificationsPage {
            anchors.fill: parent
            layout: root.layout
            onBack: root.backToMain()
        }
    }
}