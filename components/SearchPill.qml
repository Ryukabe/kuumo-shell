import QtQuick
import "../styles"
import "../state"

// A search field that rests as a small magnifier button in a corner and pulls out sideways
// into a text field (and shrinks back) with a spring. The caller anchors its right edge, so it
// grows to the left while the magnifier stays at the right end. Click the magnifier, or call
// expand(), to open it; collapse() closes it and clears the text. The hint types itself out when
// it opens (BackspaceText). What you type shows as normal text. Shared by the theme and
// wallpaper switchers.
Item {
    id: root

    // Height of the pill, and its width when open (from the island's layout block)
    required property int pillHeight
    required property int expandedWidth
    property int pixelSize: Theme.fontSizeMd
    property string placeholder: ""

    property bool expanded: false
    property alias text: field.text

    // A key reached the field; set event.accepted when you handle it
    signal keyPressed(var event)
    // The pill closed, so the caller can take the keyboard back
    signal collapsed()

    function expand() {
        root.expanded = true
        field.forceActiveFocus()
    }

    // Opens with a first character already typed (typing while the pill is closed)
    function expandWith(first) {
        root.expanded = true
        field.text = first
        field.cursorPosition = first.length
        field.forceActiveFocus()
    }

    function collapse() {
        if (!root.expanded) return
        root.expanded = false
        field.text = ""
        root.collapsed()
    }

    height: root.pillHeight
    width: grow.value
    clip: true

    Spring {
        id: grow
        target: root.expanded ? root.expandedWidth : root.pillHeight
        response: Motion.searchPill.response
        dampingFraction: Motion.searchPill.damping
        animated: !ShellState.motionReduced
    }
    Component.onCompleted: grow.snap()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusFull
        color: Theme.subBg
    }

    // The field fills the pill to the left of the magnifier
    TextInput {
        id: field
        x: Theme.spacingMd
        width: Math.max(0, root.width - root.pillHeight - Theme.spacingMd)
        height: root.pillHeight
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        selectionColor: Theme.elevatedBg
        selectedTextColor: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
        clip: true
        selectByMouse: true
        enabled: root.expanded
        opacity: root.expanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.expanded ? Motion.fadeIn : Motion.fadeOut
                easing.type: Easing.OutCubic
            }
        }

        // While the field is empty the hint's own caret shows instead of this one
        cursorDelegate: Rectangle {
            width: Theme.caretWidth
            color: Theme.fg
            opacity: field.text === "" ? 0 : 1
        }

        Keys.onPressed: event => root.keyPressed(event)
    }

    // The hint: types itself out when the pill opens
    BackspaceText {
        x: field.x
        y: (root.pillHeight - height) / 2
        height: implicitHeight
        visible: field.text === ""
        opacity: root.expanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.expanded ? Motion.fadeIn : Motion.fadeOut
                easing.type: Easing.OutCubic
            }
        }
        playing: root.expanded
        text: root.placeholder
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: root.pixelSize
    }

    // The magnifier: a button while closed, the end of the field while open. It stays at the right end.
    Text {
        x: root.width - root.pillHeight
        width: root.pillHeight
        height: root.pillHeight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "search"
        color: root.expanded ? Theme.fg : Theme.fgMuted
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
    }

    MouseArea {
        x: root.width - root.pillHeight
        width: root.pillHeight
        height: root.pillHeight
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded ? root.collapse() : root.expand()
    }
}