import QtQuick
import "../../styles"
import "../notifications"

// One notification in the list: app icon, title, the first lines of the text, and a
// button to dismiss it.
Item {
    id: row

    // The control layout block from Island.qml (sizes)
    required property var layout
    // The notification (set by the list)
    required property var modelData

    height: layout.noteRowH

    // Background
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Theme.elevatedBg
    }

    // ── App icon, or a bell when the app sent none ──
    Rectangle {
        id: iconBox
        x: row.layout.netPad
        anchors.verticalCenter: parent.verticalCenter
        width: row.layout.noteIconSize
        height: width
        radius: row.layout.noteIconRadius
        color: Theme.subBg

        Image {
            id: iconImage
            anchors.fill: parent
            source: NotificationService.iconSource(row.modelData)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent
            visible: iconImage.status !== Image.Ready
            text: "notifications"
            color: Theme.fgMuted
            font.family: Theme.fontIcon
            font.pixelSize: row.layout.noteIconSize / 2
        }
    }

    // ── Texts ──
    Column {
        x: iconBox.x + iconBox.width + row.layout.noteIconGap
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - dismiss.width - 2 * row.layout.netPad

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: row.modelData.summary
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeMd
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            text: row.modelData.body
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
        }
    }

    // ── Dismiss ──
    Item {
        id: dismiss
        anchors.right: parent.right
        anchors.rightMargin: row.layout.netPad
        anchors.verticalCenter: parent.verticalCenter
        width: row.layout.noteCloseSize
        height: width

        Text {
            anchors.centerIn: parent
            text: "close"
            color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, closeArea.containsMouse ? 1 : 0))
            font.family: Theme.fontIcon
            font.pixelSize: row.layout.noteCloseSize
        }

        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationService.dismiss(row.modelData)
        }
    }
}