pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import "../styles"

// A pick-one list in the moon style: a button with the current choice that opens a list
// below it. It does not change `value` itself: it says picked(value) and the owner decides.
Item {
    id: root

    // The choices: [{ value: "dark", label: "Dark" }, ...]
    property var options: []
    // The value of the chosen option
    property var value

    // Sizes; the defaults suit a settings row
    property int controlWidth: 180
    property int controlHeight: 34
    property int optionHeight: 34
    property int gap: 4
    property int padX: 12
    property int borderWidth: 1
    property real disabledOpacity: 0.4

    signal picked(var value)

    readonly property var current: root.options.find(o => o.value === root.value)

    implicitWidth: root.controlWidth
    implicitHeight: root.controlHeight
    opacity: root.enabled ? 1 : root.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.elevatedBg
        border.width: root.borderWidth
        border.color: Theme.border
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.padX
        anchors.right: chevron.left
        anchors.rightMargin: root.padX
        anchors.verticalCenter: parent.verticalCenter
        text: root.current ? root.current.label : ""
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
        elide: Text.ElideRight
    }

    Text {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: root.padX
        anchors.verticalCenter: parent.verticalCenter
        text: "expand_more"
        color: Theme.fgMuted
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
        rotation: popup.opened ? 180 : 0
        Behavior on rotation {
            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    Popup {
        id: popup
        parent: root
        y: root.height + root.gap
        width: root.width
        padding: 0
        // Pressing the button itself must not count as "outside", or it would close and reopen
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }

        background: Rectangle {
            radius: Theme.radiusSmall
            color: Theme.elevatedBg
            border.width: root.borderWidth
            border.color: Theme.border
        }

        contentItem: Column {
            Repeater {
                model: root.options

                delegate: Item {
                    id: option
                    required property var modelData

                    readonly property bool selected: option.modelData.value === root.value

                    width: root.width
                    height: root.optionHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSmall
                        color: Theme.subBg
                        opacity: optionMouse.containsMouse ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: root.padX
                        anchors.right: check.left
                        anchors.rightMargin: root.padX
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.modelData.label
                        color: Theme.fg
                        font.family: Theme.fontText
                        font.pixelSize: Theme.fontSizeSm
                        elide: Text.ElideRight
                    }

                    Text {
                        id: check
                        anchors.right: parent.right
                        anchors.rightMargin: root.padX
                        anchors.verticalCenter: parent.verticalCenter
                        text: "check"
                        color: Theme.fg
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeLg
                        visible: option.selected
                    }

                    MouseArea {
                        id: optionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.picked(option.modelData.value)
                            popup.close()
                        }
                    }
                }
            }
        }
    }
}