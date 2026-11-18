import QtQuick
import "../styles"
import "../state"

// A search field that rests as a small magnifier button and grows into a text field (and shrinks
// back) with a spring. Click the magnifier, or call expand(), to open it; collapse() closes it
// and clears the text. The placeholder types itself out when it opens. Shared by the theme
// and wallpaper switchers.
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
        field.forceFieldFocus()
    }

    // Opens with a first character already typed (typing while the pill is closed)
    function expandWith(first) {
        root.expanded = true
        field.text = first
        field.input.cursorPosition = first.length
        field.forceFieldFocus()
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

    // The magnifier: a button while closed, the start of the field while open
    Text {
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
        width: root.pillHeight
        height: root.pillHeight
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded ? root.collapse() : root.expand()
    }

    TypeField {
        id: field
        x: root.pillHeight
        width: root.width - x - Theme.spacingMd
        height: root.pillHeight
        placeholder: root.placeholder
        pixelSize: root.pixelSize
        playing: root.expanded
        enabled: root.expanded
        opacity: root.expanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.expanded ? Motion.fadeIn : Motion.fadeOut
                easing.type: Easing.OutCubic
            }
        }

        onKeyPressed: event => root.keyPressed(event)
    }
}