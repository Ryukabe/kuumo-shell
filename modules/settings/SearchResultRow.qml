import QtQuick
import "../../styles"

// One search result: the icon of its page, its title, and where it lives.
Item {
    id: root

    // { id, title, page, subtitle, keywords, icon }
    required property var entry
    property bool highlighted: false

    signal clicked()
    signal hovered()

    height: SettingsLayout.resultH

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.elevatedBg
        opacity: root.highlighted ? 1 : 0
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
        color: root.highlighted ? Theme.fg : Theme.fgMuted
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: SettingsLayout.iconGap
        anchors.right: parent.right
        anchors.rightMargin: SettingsLayout.itemPad
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.entry.title
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeSm
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.entry.subtitle
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.clicked()
    }
}