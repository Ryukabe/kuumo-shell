import QtQuick
import "../../styles"

// The top of a control-center page: a back arrow, the page title, and a small note on the
// right (which can be tappable, like "Clear all").
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout

    property string title: ""
    property string note: ""             // small text on the right
    property bool noteShown: true        // fades the note in and out
    property bool noteTappable: false    // the note is a button

    // The back arrow was tapped
    signal back()
    // The note was tapped (only when noteTappable)
    signal noteClicked()

    height: layout.headerH

    // Back arrow
    Item {
        id: backButton
        width: root.layout.headerH
        height: width

        Text {
            anchors.centerIn: parent
            text: "arrow_back"
            color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, backArea.containsMouse ? 1 : 0))
            font.family: Theme.fontIcon
            font.pixelSize: root.layout.headerIconSize
        }

        MouseArea {
            id: backArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.back()
        }
    }

    Text {
        x: backButton.width
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeMd
        font.weight: Font.DemiBold
    }

    // The note on the right
    Text {
        id: noteText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.note
        color: Qt.tint(Theme.fgMuted, Qt.alpha(Theme.fg, noteArea.containsMouse ? 1 : 0))
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
        opacity: root.noteShown && root.note !== "" ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Motion.fadeIn; easing.type: Easing.OutCubic }
        }

        // A little bigger than the text so it is easy to hit
        MouseArea {
            id: noteArea
            anchors.fill: parent
            anchors.margins: -Theme.spacingSm
            enabled: root.noteTappable && root.noteShown
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.noteClicked()
        }
    }
}