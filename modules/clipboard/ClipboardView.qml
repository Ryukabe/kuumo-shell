import QtQuick
import Quickshell
import "../../styles"
import "../../state"

// The clipboard island: a search field on top, what you copied before as a list below.
// Enter copies the highlighted item back and closes the island. Delete removes it and
// Ctrl+P pins it. The same two actions show as buttons on the highlighted row.
Item {
    id: root

    // Sizes from layouts.clipboard in Island.qml, and how far the content has faded in (0..1)
    property var layout
    property real reveal: 0

    opacity: reveal
    visible: reveal > 0

    // A fresh list and the keyboard as soon as the content shows
    onVisibleChanged: {
        if (!visible) return
        ClipboardService.refresh()
        input.forceActiveFocus()
    }

    // Closing clears the search, so the next opening starts empty
    Connections {
        target: IslandState
        function onClipboardChanged() {
            if (!IslandState.clipboard) input.text = ""
        }
    }

    function highlighted() { return ClipboardService.rows[list.currentIndex] }

    function copyHighlighted() {
        const item = root.highlighted()
        if (!item) return
        ClipboardService.copy(item)
        IslandState.closeAll()
    }

    function removeHighlighted() {
        const item = root.highlighted()
        if (item) ClipboardService.remove(item)
    }

    function pinHighlighted() {
        const item = root.highlighted()
        if (item) ClipboardService.togglePin(item)
    }

    // The icon at the start of the search field. It lines up with the squares of the rows.
    Text {
        id: fieldIcon
        x: root.layout.padX + root.layout.rowPad
        y: root.layout.padTop
        width: root.layout.thumb
        height: root.layout.searchH
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "content_paste"
        color: Theme.fg
        font.family: Theme.fontIcon
        font.pixelSize: root.layout.iconSize
    }

    // The search field, in line with the text of the rows
    TextInput {
        id: input
        x: fieldIcon.x + root.layout.thumb + root.layout.iconGap
        y: root.layout.padTop
        width: root.width - x - root.layout.padX - root.layout.rowPad
        height: root.layout.searchH
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: root.layout.fontSize
        clip: true
        selectByMouse: true

        onTextChanged: ClipboardService.query = text

        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onReturnPressed: root.copyHighlighted()
        Keys.onEnterPressed: root.copyHighlighted()
        Keys.onDeletePressed: root.removeHighlighted()
        Keys.onEscapePressed: IslandState.closeAll()

        // Ctrl+P pins or unpins the highlighted item
        Keys.onPressed: event => {
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                root.pinHighlighted()
                event.accepted = true
            }
        }
    }

    // Hint shown while the field is empty
    Text {
        x: input.x
        y: input.y
        height: input.height
        verticalAlignment: Text.AlignVCenter
        text: "Search clipboard"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: root.layout.fontSize
        visible: input.text === ""
    }

    // ── The list: one row each, scrolls after maxRows ──
    ListView {
        id: list
        x: root.layout.padX
        y: root.layout.padTop + root.layout.searchH + root.layout.listGap
        width: root.width - 2 * root.layout.padX
        height: root.layout.maxRows * root.layout.rowH
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ClipboardService.rows
        currentIndex: 0

        // A new search (or a changed list) starts at the top
        onModelChanged: currentIndex = 0

        delegate: Item {
            id: row
            required property var modelData
            required property int index

            readonly property bool current: index === list.currentIndex
            // The picture file of an image item, or "" while it is not ready
            readonly property string thumb: ClipboardService.thumbPath(modelData.id)
            readonly property bool showsPicture: modelData.isImage && thumb !== ""

            width: list.width
            height: root.layout.rowH

            // A picture is decoded once, the first time its row exists
            Component.onCompleted: if (modelData.isImage) ClipboardService.ensureThumb(modelData.id)

            // Highlight behind the selected row
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: Theme.subBg
                opacity: row.current ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                }
            }

            // Click or hover on the row. Declared before the buttons so they sit on top.
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.currentIndex = row.index
                onClicked: {
                    list.currentIndex = row.index
                    root.copyHighlighted()
                }
            }

            // The square on the left: the picture for an image, the clipboard icon otherwise.
            // The icon is brighter on the highlighted row, so it stays easy to see on it.
            Item {
                id: square
                x: root.layout.rowPad
                anchors.verticalCenter: parent.verticalCenter
                width: root.layout.thumb
                height: root.layout.thumb
                clip: true

                Image {
                    anchors.fill: parent
                    visible: row.showsPicture
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width, height)
                    source: row.showsPicture ? "file://" + row.thumb : ""
                }

                Text {
                    anchors.fill: parent
                    visible: !row.showsPicture
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.isImage ? "image" : "content_paste"
                    color: row.current ? Theme.fg : Theme.fgMuted
                    Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
                    font.family: Theme.fontIcon
                    font.pixelSize: root.layout.iconSize
                }
            }

            // The pin and delete buttons on the right. The pin also stays visible on a
            // pinned item.
            Row {
                id: actions
                anchors.right: parent.right
                anchors.rightMargin: root.layout.rowPad
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.layout.actionGap

                Text {
                    text: "push_pin"
                    color: row.modelData.pinned ? Theme.accent : Theme.fgMuted
                    font.family: Theme.fontIcon
                    font.pixelSize: root.layout.actionSize
                    opacity: row.current || row.modelData.pinned ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.opacity > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClipboardService.togglePin(row.modelData)
                    }
                }

                Text {
                    text: "delete"
                    color: Theme.fgMuted
                    font.family: Theme.fontIcon
                    font.pixelSize: root.layout.actionSize
                    opacity: row.current ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.opacity > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClipboardService.remove(row.modelData)
                    }
                }
            }

            // The preview (a picture says what it is), and under it the size and age
            Column {
                anchors.left: square.right
                anchors.leftMargin: root.layout.iconGap
                anchors.right: actions.left
                anchors.rightMargin: root.layout.iconGap
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: row.modelData.isImage
                        ? "Image · " + row.modelData.format + " " + row.modelData.dims
                        : row.modelData.preview
                    color: Theme.fg
                    font.family: Theme.fontText
                    font.pixelSize: root.layout.previewFont
                    wrapMode: Text.Wrap
                    maximumLineCount: row.modelData.isImage ? 1 : root.layout.previewLines
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: ClipboardService.detail(row.modelData, ClipboardService.now)
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Shown instead of the list when there is nothing to list
    Text {
        x: list.x
        y: list.y
        width: list.width
        height: root.layout.rowH
        visible: ClipboardService.rows.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: ClipboardService.items.length === 0 ? "Nothing copied yet" : "No matches"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }
}