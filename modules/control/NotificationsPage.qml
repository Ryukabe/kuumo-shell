pragma ComponentBehavior: Bound

import QtQuick
import "../../styles"
import "../notifications"

// The notifications page of the control center: every notification, newest first.
// Dismiss one with its cross, or everything with "Clear all".
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout

    // The back arrow was tapped
    signal back()

    PageHeader {
        id: header
        layout: root.layout
        width: parent.width
        title: "Notifications"
        note: "Clear all"
        noteShown: NotificationService.count > 0
        noteTappable: true
        onNoteClicked: NotificationService.clearAll()
        onBack: root.back()
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: root.layout.rowGap
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: root.layout.netRowGap
        boundsBehavior: Flickable.StopAtBounds
        model: NotificationService.items

        delegate: NotificationRow {
            layout: root.layout
            width: list.width
        }
    }

    // Shown instead of the list when there is nothing to list
    Text {
        anchors.centerIn: list
        visible: NotificationService.count === 0
        text: "No notifications"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }
}