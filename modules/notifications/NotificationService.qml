pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../.." as Root

// Notifications. The shell is the notification receiver: apps send their notifications
// here. Each one is kept in a list, counted as unread, and (unless Focus is on) shown
// as a toast that the island grows into for a few seconds.
Singleton {
    id: root

    // ── Focus (do not disturb) ──
    // On: notifications are still collected in the list, but no toast pops up.
    // It is kept in state/notifications.json, so it survives a restart.
    property bool focusOn: false

    function toggleFocus() {
        focusOn = !focusOn
        save()
    }

    // ── Quiet start ──
    // When the shell starts, some apps send their notifications again (to them a restart
    // looks like a new notification service), and Focus is still being read from its file.
    // So for the first startupQuietMs no toast pops up. Notifications are still collected.
    // (This could move into Config.qml with the other notification settings.)
    readonly property int startupQuietMs: 5000
    property bool starting: true

    Timer {
        interval: root.startupQuietMs
        running: true
        onTriggered: root.starting = false
    }

    // ── The list ──
    readonly property var notificationModel: server.trackedNotifications
    readonly property var items: Array.from(notificationModel["values"]).reverse()  // newest first
    readonly property int count: items.length
    readonly property string latestSummary: count > 0 ? items[0].summary : ""

    // Arrived since the notifications page was last looked at
    property int unread: 0

    // Dismissed notifications leave the list, so unread can never be more than what is left
    onCountChanged: unread = Math.min(unread, count)

    function markAllRead() { unread = 0 }

    function dismiss(notification) { notification.dismiss() }

    function clearAll() {
        for (const notification of Array.from(notificationModel["values"])) notification.dismiss()
    }

    // The picture for a notification: the image it came with, else its app's icon
    function iconSource(notification) {
        if (notification.image !== "") return notification.image
        if (notification.appIcon === "") return ""
        // A full path is used as it is; a name is looked up in the icon theme
        return notification.appIcon.startsWith("/")
            ? notification.appIcon
            : Quickshell.iconPath(notification.appIcon, true)
    }

    // ── The toast ──
    property bool toastActive: false    // the toast is showing
    property bool toastHeld: false      // the pointer is over it, so it stays
    // What the toast shows. A plain copy, kept after the toast hides so the text
    // does not vanish while it fades out.
    property var toast: ({ appName: "", summary: "", body: "", icon: "" })

    function showToast(notification) {
        toast = {
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            icon: iconSource(notification)
        }
        toastActive = true
        toastTimer.restart()
    }

    function hideToast() { toastActive = false }

    Timer {
        id: toastTimer
        interval: Root.Config.notificationToastMs
        running: root.toastActive && !root.toastHeld
        onTriggered: root.hideToast()
    }

    // ── Receiving ──
    NotificationServer {
        id: server

        // Plain text only: no markup in the body
        bodyMarkupSupported: false
        imageSupported: true
        // The list keeps notifications until they are dismissed
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true    // keeps it in the list
            root.unread += 1
            // No toast with Focus on, or during the quiet start
            if (!root.focusOn && !root.starting) root.showToast(notification)
        }
    }

    // ── Saving ──
    function save() {
        store.setText(JSON.stringify({ focusOn: focusOn }))
    }

    FileView {
        id: store
        path: Quickshell.shellPath("state/notifications.json")

        // Read once at start. With no file yet (or one that cannot be read) Focus stays off.
        onLoaded: {
            try {
                root.focusOn = JSON.parse(store.text()).focusOn === true
            } catch (error) {
                root.focusOn = false
            }
        }
    }
}