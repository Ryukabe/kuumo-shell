import QtQuick
import "../../styles"

// One entry of the sidebar: an icon and a title. The current page is highlighted.
Item {
    id: root

    // One entry of SettingsNav.pages: { id, title, icon, file }
    required property var entry

    readonly property bool current: SettingsNav.page === root.entry.id

    signal clicked()

    width: parent.width
    height: SettingsLayout.itemH

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.elevatedBg
        opacity: root.current ? 1 : mouse.containsMouse ? SettingsLayout.hoverOpacity : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
        }
    }

    Text {
        id: icon
        x: SettingsLayout.itemPad
        width: Theme.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.entry.icon
        color: root.current ? Theme.fg : Theme.fgMuted
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
    }

    Text {
        anchors.left: icon.right
        anchors.leftMargin: SettingsLayout.iconGap
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.title
        color: root.current ? Theme.fg : Theme.fgMuted
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}