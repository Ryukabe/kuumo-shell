pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../styles"
import "../../state"

// The launcher island: a search field on top, the matching rows as a list below. A row
// is an app, or a calculator / conversion answer.
Item {
    id: root

    // Sizes from layouts.launcher in Island.qml, and how far the content has faded in (0..1)
    property var layout
    property real reveal: 0

    opacity: reveal
    visible: reveal > 0

    // Take the keyboard as soon as the content shows
    onVisibleChanged: if (visible) input.forceActiveFocus()

    // Closing clears the search, so the next opening starts empty
    Connections {
        target: IslandState
        function onLauncherChanged() {
            if (!IslandState.launcher) input.text = ""
        }
    }

    // Start the highlighted row
    function launchCurrent() {
        const row = LauncherService.results[list.currentIndex]
        if (row) LauncherService.activate(row)
    }

    // The search field
    TextInput {
        id: input
        x: root.layout.padX
        y: root.layout.padTop
        width: root.width - 2 * root.layout.padX
        height: root.layout.searchH
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: root.layout.fontSize
        clip: true
        selectByMouse: true

        onTextChanged: LauncherService.query = text

        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onReturnPressed: root.launchCurrent()
        Keys.onEnterPressed: root.launchCurrent()
        Keys.onEscapePressed: IslandState.closeAll()
    }

    // Hint shown while the field is empty
    Text {
        x: input.x
        y: input.y
        height: input.height
        verticalAlignment: Text.AlignVCenter
        text: "Search apps"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: root.layout.fontSize
        visible: input.text === ""
    }

    // The results: one row each, scrolls after maxRows
    ListView {
        id: list
        x: root.layout.padX
        y: root.layout.padTop + root.layout.searchH + root.layout.listGap
        width: root.width - 2 * root.layout.padX
        height: root.layout.maxRows * root.layout.rowH
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: LauncherService.results
        currentIndex: 0

        // A new search starts at the top
        onModelChanged: currentIndex = 0

        delegate: Item {
            id: row
            required property var modelData
            required property int index

            // An answer row shows "=" where an app shows its icon
            readonly property bool isCalc: modelData.kind === "calc"

            width: list.width
            height: root.layout.rowH

            // Highlight behind the selected row
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: Theme.subBg
                opacity: row.index === list.currentIndex ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                }
            }

            Item {
                id: iconSlot
                x: root.layout.rowPad
                anchors.verticalCenter: parent.verticalCenter
                width: root.layout.iconSize
                height: root.layout.iconSize

                Image {
                    anchors.fill: parent
                    visible: !row.isCalc
                    sourceSize: Qt.size(width, height)
                    source: row.isCalc ? "" : Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                }

                Text {
                    anchors.centerIn: parent
                    visible: row.isCalc
                    text: "="
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: root.layout.fontSize
                }
            }

            // Name (or the answer), and under it the small line of an answer row
            Column {
                anchors.left: iconSlot.right
                anchors.leftMargin: root.layout.iconGap
                anchors.right: parent.right
                anchors.rightMargin: root.layout.rowPad
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: row.modelData.name
                    color: Theme.fg
                    font.family: Theme.fontText
                    font.pixelSize: root.layout.fontSize
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.sub
                    color: Theme.fgMuted
                    font.family: Theme.fontText
                    font.pixelSize: Theme.fontSizeXs
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.currentIndex = row.index
                onClicked: LauncherService.activate(row.modelData)
            }
        }
    }
}