import QtQuick
import "../../styles"

// The toast: the island grows into this for a few seconds when a notification arrives.
// App icon on the left, then the app name, the title and the first line of the text.
// Click it to hide it (the notification stays in the list).
Item {
    id: root

    // The toast layout block from Island.qml
    required property var layout
    // 0..1, how far the toast content has appeared (from Island.qml)
    required property real reveal

    // What to show (a copy kept by the service)
    readonly property var toast: NotificationService.toast

    width: layout.w - 2 * layout.padX
    height: Math.max(layout.iconSize, textColumn.implicitHeight)
    opacity: reveal
    enabled: reveal > 0.5

    // ── App icon, or a bell when the app sent none ──
    Rectangle {
        id: iconBox
        width: root.layout.iconSize
        height: width
        anchors.verticalCenter: parent.verticalCenter
        radius: root.layout.iconRadius
        color: Theme.elevatedBg

        Image {
            id: iconImage
            anchors.fill: parent
            source: root.toast.icon
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent
            visible: iconImage.status !== Image.Ready
            text: "notifications"
            color: Theme.fgMuted
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.iconSize / 2
        }
    }

    // ── Texts ──
    Column {
        id: textColumn
        x: root.layout.iconSize + root.layout.iconGap
        width: root.width - x
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.toast.appName
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.toast.summary
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeMd
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 1
            text: root.toast.body
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeSm
        }
    }

    // Click to hide the toast
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.hideToast()
    }
}