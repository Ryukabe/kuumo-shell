import QtQuick
import "../../styles"
import "../notifications"

// The notifications card at the bottom of the main page: a bell (with a pulsing dot while
// there is something unread) and the latest notification. Tap it to open the list.
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout

    // The card was tapped
    signal clicked()

    readonly property int unread: NotificationService.unread

    height: layout.cardH

    // Background
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Qt.tint(Theme.elevatedBg, Qt.alpha(Theme.border, area.containsMouse ? 1 : 0))
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
    }

    // ── The bell, with the dot ──
    Item {
        id: bell
        x: root.layout.netPad
        anchors.verticalCenter: parent.verticalCenter
        width: root.layout.cardIconSize
        height: width

        Text {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // A crossed-out bell while Focus is on
            text: NotificationService.focusOn ? "notifications_off" : "notifications"
            color: root.unread > 0 ? Theme.fg : Theme.fgMuted
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.cardIconSize
        }

        // Pulses while there is something unread
        Rectangle {
            id: dot
            visible: root.unread > 0
            width: root.layout.bellDot
            height: width
            radius: width / 2
            x: parent.width - width
            y: 0
            color: Theme.accent

            SequentialAnimation on opacity {
                running: dot.visible
                loops: Animation.Infinite
                NumberAnimation { to: Theme.dimOpacity; duration: Motion.breatheMs / 2; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: Motion.breatheMs / 2; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Texts ──
    Column {
        x: bell.x + bell.width + root.layout.netIconGap
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - chevron.width - 2 * root.layout.netPad

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.unread > 0 ? root.unread + " new" : "Notifications"
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeMd
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.unread > 0 ? NotificationService.latestSummary
                : NotificationService.focusOn ? "Focus is on" : "All caught up"
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
        }
    }

    // Arrow on the right
    Text {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: root.layout.netPad
        anchors.verticalCenter: parent.verticalCenter
        text: "chevron_right"
        color: Theme.fgMuted
        font.family: Theme.fontIcon
        font.pixelSize: root.layout.cardIconSize
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}