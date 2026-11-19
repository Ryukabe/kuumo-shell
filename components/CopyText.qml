import QtQuick
import "../styles"
import "../state"

// Content you press to copy. Whatever you put inside slides up and out of sight while "Copied"
// (with a check) rises in its place; after resetDelay the content comes back. Pressing again
// while it shows restarts the wait, so nothing flickers. It does not copy by itself: the press
// emits copyRequested(), the caller copies (so the clipboard service stays the one place that
// does) and then calls markCopied() or markFailed(). With reduced motion the two cross-fade.
Item {
    id: root

    // The content: anything you declare inside CopyText goes here
    default property alias content: normal.data

    property string copiedLabel: "Copied"
    property string failedLabel: "Couldn't copy"
    property int resetDelay: Motion.copyResetMs
    // A press anywhere on it asks for a copy; turn this off to call press() yourself
    property bool clickable: true

    property color color: Theme.fg
    property font font
    font.family: Theme.fontText
    font.pixelSize: Theme.fontSizeSm

    // "idle" | "copied" | "failed"
    property string status: "idle"

    signal copyRequested()

    function press() { root.copyRequested() }

    function markCopied() {
        root.status = "copied"
        reset.restart()
    }

    function markFailed() {
        root.status = "failed"
        reset.restart()
    }

    Timer {
        id: reset
        interval: root.resetDelay
        onTriggered: root.status = "idle"
    }

    // 0 = the content shows, 1 = the notice shows
    property real away: root.status === "idle" ? 0 : 1
    Behavior on away {
        NumberAnimation { duration: Motion.copySlideMs; easing.type: Easing.OutCubic }
    }

    readonly property bool slides: !ShellState.motionReduced

    clip: true

    Item {
        id: normal
        width: root.width
        height: root.height
        y: root.slides ? -root.away * root.height : 0
        opacity: root.slides ? 1 : 1 - root.away
    }

    Row {
        id: notice
        height: root.height
        spacing: Theme.spacingSm
        y: root.slides ? (1 - root.away) * root.height : 0
        opacity: root.slides ? 1 : root.away

        Text {
            height: root.height
            verticalAlignment: Text.AlignVCenter
            text: root.status === "failed" ? "close" : "check"
            color: root.color
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeLg
        }

        Text {
            height: root.height
            verticalAlignment: Text.AlignVCenter
            text: root.status === "failed" ? root.failedLabel : root.copiedLabel
            color: root.color
            font: root.font
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.press()
    }
}