pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtQuick.Controls.Basic
import "../../styles"

// The Settings window: a normal floating window with the sidebar on the left and the open
// page on the right. Esc closes it, Ctrl+F searches. SettingsNav says whether it is open
// and which page. The outside triggers (qs ipc call settings ...) are in core/ipc/.
FloatingWindow {
    id: root

    // A Hyprland window rule can match this title
    title: "kuumo-settings"
    color: Theme.bg
    visible: SettingsNav.open
    implicitWidth: SettingsLayout.windowW
    implicitHeight: SettingsLayout.windowH
    minimumSize: Qt.size(SettingsLayout.minW, SettingsLayout.minH)

    // Closed from outside (by the compositor): keep SettingsNav in step
    onVisibleChanged: if (!visible) SettingsNav.open = false

    // Apply the saved settings now, so they hold even if this window is never opened
    Component.onCompleted: SettingsState.start()

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: SettingsNav.hide()
        Keys.onPressed: event => {
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
                search.focusField()
                event.accepted = true
            }
        }

        // ── The sidebar ──
        Rectangle {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: SettingsLayout.sidebarW
            color: Theme.subBg

            Text {
                id: sidebarTitle
                x: SettingsLayout.sidebarPad + SettingsLayout.itemPad
                y: SettingsLayout.sidebarPad
                height: SettingsLayout.itemH
                verticalAlignment: Text.AlignVCenter
                text: "Settings"
                color: Theme.fg
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.DemiBold
            }

            SearchField {
                id: search
                anchors.top: sidebarTitle.bottom
                anchors.topMargin: SettingsLayout.itemGap
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: SettingsLayout.sidebarPad
                anchors.rightMargin: SettingsLayout.sidebarPad

                onMoveDown: results.next()
                onMoveUp: results.previous()
                onAccepted: results.openCurrent()
            }

            // The pages, while nothing is typed. Scrolls when the window is too short for them all.
            Flickable {
                id: pagesFlick
                anchors.top: search.bottom
                anchors.topMargin: SettingsLayout.sidebarPad
                anchors.bottom: parent.bottom
                anchors.bottomMargin: SettingsLayout.sidebarPad
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: SettingsLayout.sidebarPad
                anchors.rightMargin: SettingsLayout.sidebarPad
                visible: search.text === ""
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: pagesColumn.height

                ScrollBar.vertical: ScrollBar {
                    id: pagesBar
                    policy: ScrollBar.AsNeeded
                    minimumSize: 0.1
                    padding: 2

                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: width / 2
                        color: Theme.fgMuted
                        opacity: pagesBar.pressed ? 0.8 : (pagesBar.hovered || pagesBar.active) ? 0.5 : 0.2
                        Behavior on opacity {
                            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                        }
                    }
                    background: Item {}
                }

                Column {
                    id: pagesColumn
                    width: pagesFlick.width
                    spacing: SettingsLayout.itemGap

                    Repeater {
                        model: SettingsNav.pages

                        delegate: SidebarItem {
                            required property var modelData
                            entry: modelData
                            onClicked: SettingsNav.goTo(entry.id)
                        }
                    }
                }
            }

            // The results, once something is typed
            SearchResults {
                id: results
                anchors.top: search.bottom
                anchors.topMargin: SettingsLayout.sidebarPad
                anchors.bottom: parent.bottom
                anchors.bottomMargin: SettingsLayout.sidebarPad
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: SettingsLayout.sidebarPad
                anchors.rightMargin: SettingsLayout.sidebarPad
                visible: search.text !== ""
                query: search.text

                onOpened: search.clear()
            }
        }

        // The line between the sidebar and the page
        Rectangle {
            id: divider
            anchors.left: sidebar.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: SettingsLayout.borderW
            color: Theme.border
        }

        // ── The open page ──
        Loader {
            id: pageLoader
            anchors.left: divider.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            source: SettingsNav.pagesDir + SettingsNav.current.file
            onLoaded: fade.restart()
        }

        NumberAnimation {
            id: fade
            target: pageLoader
            property: "opacity"
            from: 0
            to: 1
            duration: Motion.hoverFade
            easing.type: Easing.OutCubic
        }
    }
}