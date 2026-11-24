pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../components"
import "../../styles"
import "../../state"
import "../.." as Root

// The launcher island: a search field on top, the matching rows as a list below. A row
// is an app, a calculator / conversion answer, a suggestion for finishing a conversion,
// a setting (in the settings command), or (in command mode) a command. Enter on a command
// opens its view. The emoji picker shows its emoji as a grid instead of a list, with the
// name of the emoji you are on under it.
Item {
    id: root

    // Sizes from layouts.launcher in Island.qml, and how far the content has faded in (0..1)
    property var layout
    property real reveal: 0

    opacity: reveal
    visible: reveal > 0

    // Where the list or grid starts, and how many rows of emoji the grid shows right now
    readonly property real listTop: layout.padTop + layout.searchH + layout.listGap
    readonly property int gridRowsShown: Math.min(Math.ceil(grid.count / layout.emojiCols), layout.emojiRows)

    // Take the keyboard as soon as the content shows
    onVisibleChanged: if (visible) input.forceActiveFocus()

    // Closing clears the search, so the next opening starts empty
    Connections {
        target: IslandState
        function onLauncherChanged() {
            if (!IslandState.launcher) input.text = ""
        }
    }

    Connections {
        target: LauncherService

        // A suggestion was picked: its text goes into the search field, cursor at the end
        function onFillRequested(text) {
            input.text = text
            input.cursorPosition = text.length
            input.forceActiveFocus()
        }

        // Opening or closing a command starts its search empty
        function onActiveCommandChanged() {
            input.text = ""
        }
    }

    // Start the highlighted row
    function launchCurrent() {
        const index = LauncherService.gridView ? grid.currentIndex : list.currentIndex
        const row = LauncherService.results[index]
        if (row) LauncherService.activate(row)
    }

    // Move the highlight: up and down in a list; in the emoji grid also left and right
    function move(dx, dy) {
        if (LauncherService.gridView) {
            const last = grid.count - 1
            if (last < 0) return
            const step = dx + dy * root.layout.emojiCols
            grid.currentIndex = Math.max(0, Math.min(last, grid.currentIndex + step))
        } else if (dy > 0) {
            list.incrementCurrentIndex()
        } else if (dy < 0) {
            list.decrementCurrentIndex()
        }
    }

    // Left or right on a setting row changes it (big takes five steps)
    function nudge(direction, big) {
        const row = LauncherService.results[list.currentIndex]
        if (row && row.kind === "setting") LauncherService.nudgeSetting(row.setting, direction, big)
    }

    // The icon at the start of the search field: a magnifier for apps, a terminal in command
    // mode, and the icon of the open command (the emoji face, ...). It lines up with the
    // icons of the rows below.
    Text {
        id: fieldIcon
        x: root.layout.padX + root.layout.rowPad
        y: root.layout.padTop
        width: root.layout.iconSize
        height: root.layout.searchH
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: LauncherService.fieldSymbol
        color: LauncherService.commandMode ? Theme.fg : Theme.fgMuted
        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
    }

    // The search field, in line with the text of the rows
    TextInput {
        id: input
        x: fieldIcon.x + root.layout.iconSize + root.layout.iconGap
        y: root.layout.padTop
        width: root.width - x - root.layout.padX - root.layout.rowPad
        height: root.layout.searchH
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        font.family: Theme.fontText
        font.pixelSize: root.layout.fontSize
        clip: true
        selectByMouse: true

        // While the field is empty the hint's own caret shows instead of this one
        cursorDelegate: Rectangle {
            width: Theme.caretWidth
            color: Theme.fg
            opacity: input.text === "" ? 0 : 1
        }

        onTextChanged: {
            // A ">" typed first switches to the commands and is taken out of the field,
            // so the field only shows what you are searching for
            if (text.startsWith(">") && !LauncherService.commandMode && !LauncherService.activeCommand) {
                LauncherService.commandMode = true
                text = text.slice(1)
                cursorPosition = text.length
                return
            }
            LauncherService.query = text
        }

        Keys.onUpPressed: root.move(0, -1)
        Keys.onDownPressed: root.move(0, 1)
        // Left and right move the highlight in the emoji grid, change the highlighted
        // setting in the settings view, and move the cursor otherwise
        Keys.onLeftPressed: event => {
            if (LauncherService.gridView) root.move(-1, 0)
            else if (LauncherService.settingsView) root.nudge(-1, !!(event.modifiers & Qt.ShiftModifier))
            else event.accepted = false
        }
        Keys.onRightPressed: event => {
            if (LauncherService.gridView) root.move(1, 0)
            else if (LauncherService.settingsView) root.nudge(1, !!(event.modifiers & Qt.ShiftModifier))
            else event.accepted = false
        }
        Keys.onReturnPressed: root.launchCurrent()
        Keys.onEnterPressed: root.launchCurrent()

        // ESC goes back out of an open command, and closes the island otherwise
        Keys.onEscapePressed: LauncherService.activeCommand
            ? LauncherService.closeCommand()
            : IslandState.closeAll()

     // Backspace in an empty field steps back: out of an open command to the command
     // list, and (when that is on in Settings) out of the command list to the apps
     Keys.onPressed: event => {
         if (event.key !== Qt.Key_Backspace || input.text !== "") return
         if (LauncherService.activeCommand) {
             LauncherService.closeCommand()
             event.accepted = true
         } else if (LauncherService.commandMode && Root.Config.launcherBackspaceLeavesCommands) {
             LauncherService.leaveCommands()
             event.accepted = true
         }
     }
    }

    // Hint shown while the field is empty: it types itself out when the island opens and
    // corrects itself when it changes (a command opens, ...)
    BackspaceText {
        x: input.x
        y: input.y + (input.height - height) / 2
        height: implicitHeight
        visible: input.text === ""
        playing: root.visible
        text: LauncherService.fieldHint
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: root.layout.fontSize
    }

    // ── The list: one row each, scrolls after maxRows ──
    ListView {
        id: list
        visible: !LauncherService.gridView
        x: root.layout.padX
        y: root.listTop
        width: root.width - 2 * root.layout.padX
        height: root.layout.maxRows * root.layout.rowH
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: LauncherService.gridView ? [] : LauncherService.results
        currentIndex: 0

        // A new search starts at the top
        onModelChanged: currentIndex = 0

        delegate: Item {
            id: row
            required property var modelData
            required property int index

            // An app has its own icon; every other row has an icon-font symbol
            readonly property bool isApp: modelData.kind === "app"
            readonly property bool isSetting: modelData.kind === "setting"
            readonly property bool current: index === list.currentIndex

            // The value of a setting row, read live so it follows every change. The
            // highlighted row shows arrows for a number or a choice, which left and right change.
            readonly property string valueText: {
                if (!row.isSetting) return ""
                const value = LauncherService.settingValue(row.modelData.setting)
                const kind = row.modelData.setting.control.kind
                return row.current && kind !== "toggle" ? "‹  " + value + "  ›" : value
            }

            width: list.width
            height: root.layout.rowH

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

            // The icon slot is as wide as an app icon so everything lines up; a symbol is
            // drawn smaller inside it, muted, and bright on the highlighted row.
            // clip: a symbol name the icon font does not know shows as text, and must not spill out
            Item {
                id: iconSlot
                x: root.layout.rowPad
                anchors.verticalCenter: parent.verticalCenter
                width: root.layout.iconSize
                height: root.layout.iconSize
                clip: true

                Image {
                    anchors.fill: parent
                    visible: row.isApp
                    sourceSize: Qt.size(width, height)
                    source: row.isApp ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                }

                Text {
                    anchors.fill: parent
                    visible: !row.isApp
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: row.isApp ? "" : row.modelData.symbol
                    color: row.current ? Theme.fg : Theme.fgMuted
                    Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeLg
                }
            }

            // The value of a setting, on the right
            Text {
                id: valueLabel
                anchors.right: parent.right
                anchors.rightMargin: root.layout.rowPad
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width * 0.4)
                visible: row.isSetting
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: row.valueText
                color: row.current ? Theme.fg : Theme.fgMuted
                Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeSm
            }

            // Name (or the answer), and under it the small line of an answer, suggestion,
            // command, setting or note
            Column {
                anchors.left: iconSlot.right
                anchors.leftMargin: root.layout.iconGap
                anchors.right: row.isSetting ? valueLabel.left : parent.right
                anchors.rightMargin: row.isSetting ? root.layout.iconGap : root.layout.rowPad
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

    // ── The emoji grid: square cells, scrolls after emojiRows ──
    GridView {
        id: grid
        visible: LauncherService.gridView
        x: (root.width - width) / 2
        y: root.listTop
        width: root.layout.emojiCols * root.layout.emojiCell
        height: root.layout.emojiRows * root.layout.emojiCell
        cellWidth: root.layout.emojiCell
        cellHeight: root.layout.emojiCell
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: LauncherService.gridView ? LauncherService.results : []
        currentIndex: 0

        // A new search starts at the top, and the highlight stays in view while you move
        onModelChanged: currentIndex = 0
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

        delegate: Item {
            id: cell
            required property var modelData
            required property int index

            width: grid.cellWidth
            height: grid.cellHeight

            // Highlight behind the emoji you are on
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: Theme.subBg
                opacity: cell.index === grid.currentIndex ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Motion.hoverFade; easing.type: Easing.OutCubic }
                }
            }

            Text {
                anchors.centerIn: parent
                text: cell.modelData.char
                font.pixelSize: root.layout.emojiSize
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: grid.currentIndex = cell.index
                onClicked: LauncherService.activate(cell.modelData)
            }
        }
    }

    // The name of the emoji you are on, under the grid
    Text {
        visible: LauncherService.gridView
        x: grid.x + root.layout.rowPad
        y: grid.y + root.gridRowsShown * root.layout.emojiCell
        width: grid.width - 2 * root.layout.rowPad
        height: root.layout.emojiCaptionH
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
        text: {
            const e = LauncherService.results[grid.currentIndex]
            return grid.count === 0 || !e ? "No emoji found" : e.char + "  " + e.name
        }
    }
}