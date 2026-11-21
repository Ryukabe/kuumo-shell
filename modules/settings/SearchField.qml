import QtQuick
import "../../components"
import "../../styles"

// The search field at the top of the sidebar. Up and Down move through the results, Enter
// opens the highlighted one, and Esc clears the field (or closes the window when it is empty).
FocusScope {
    id: root

    property alias text: input.text

    signal moveUp()
    signal moveDown()
    signal accepted()

    function focusField() {
        input.forceActiveFocus()
        input.selectAll()
    }

    function clear() { input.text = "" }

    height: SettingsLayout.searchH

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.elevatedBg
    }

    Text {
        id: searchIcon
        x: SettingsLayout.itemPad
        width: Theme.fontSizeLg
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "search"
        color: Theme.fgMuted
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
    }

    TextInput {
        id: input
        anchors.left: searchIcon.right
        anchors.leftMargin: SettingsLayout.iconGap
        anchors.right: clearButton.left
        anchors.rightMargin: SettingsLayout.iconGap
        height: parent.height
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
        clip: true
        selectByMouse: true

        // While the field is empty the hint's own caret shows instead of this one
        cursorDelegate: Rectangle {
            width: Theme.caretWidth
            color: Theme.fg
            opacity: input.text === "" ? 0 : 1
        }

        Keys.onUpPressed: root.moveUp()
        Keys.onDownPressed: root.moveDown()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: {
            if (input.text !== "") input.text = ""
            else SettingsNav.hide()
        }
    }

    // Hint shown while the field is empty: it types itself out when the window opens
    BackspaceText {
        x: input.x
        y: input.y + (input.height - height) / 2
        height: implicitHeight
        visible: input.text === ""
        playing: SettingsNav.open
        text: "Search settings"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }

    // Clears the search
    Text {
        id: clearButton
        anchors.right: parent.right
        anchors.rightMargin: SettingsLayout.itemPad
        width: Theme.fontSizeLg
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "close"
        color: Theme.fgMuted
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
        opacity: input.text === "" ? 0 : 1
        Behavior on opacity {
            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            enabled: parent.opacity > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clear()
                root.focusField()
            }
        }
    }
}