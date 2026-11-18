pragma ComponentBehavior: Bound

import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// The theme switcher island: a search pill and the name of the showing theme on top, a row of
// theme cards below (the highlighted one bigger), and the count under it. Resting on a card
// previews that theme (Config.switcherPreviewDelayMs). Enter or a click keeps it. Esc, a click
// outside or closing the island puts the saved theme back. Left and right (or the pointer)
// move the highlight; typing opens the search, and while it is open up and down move it.
Item {
    id: root

    // Sizes from layouts.theme in Island.qml, and how far the content has faded in (0..1)
    property var layout
    property real reveal: 0

    opacity: reveal
    visible: reveal > 0

    // Where the row of cards starts
    readonly property real listTop: layout.padTop + layout.searchH + layout.listGap

    // A fresh start whenever the island shows: no search, the saved theme highlighted
    onVisibleChanged: if (visible) root.open()

    function open() {
        search.collapse()
        ThemeService.query = ""
        const index = Math.max(0, ThemeService.indexOf(ThemeService.committedId))
        list.currentIndex = index
        list.positionViewAtIndex(index, ListView.Center)
        keys.forceActiveFocus()
    }

    // Moves the highlight by `step` cards
    function move(step) {
        const last = ThemeService.results.length - 1
        if (last < 0) return
        list.currentIndex = Math.max(0, Math.min(last, list.currentIndex + step))
    }

    // Keeps the highlighted theme and closes the island
    function chooseCurrent() {
        const entry = ThemeService.results[list.currentIndex]
        if (!entry) return
        previewTimer.stop()
        ThemeService.commit(entry.id)
        IslandState.collapse()
    }

    // The keys of the island, from the key catcher below and from the search field
    function handleKey(event) {
        const searching = search.expanded
        const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))

        if (event.key === Qt.Key_Down || (event.key === Qt.Key_Right && !searching)) {
            root.move(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Left && !searching)) {
            root.move(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.chooseCurrent()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            if (searching) search.collapse()
            else IslandState.closeAll()
            event.accepted = true
        } else if (!searching && plain && event.text.length > 0 && event.text >= " ") {
            // A letter typed while the search is closed opens it with that letter
            search.expandWith(event.text)
            event.accepted = true
        }
    }

    // Takes the keyboard while the search is closed
    Item {
        id: keys
        Keys.onPressed: event => root.handleKey(event)
    }

    // Previews the highlighted theme once you rest on it
    Timer {
        id: previewTimer
        interval: Root.Config.switcherPreviewDelayMs
        onTriggered: {
            const entry = ThemeService.results[list.currentIndex]
            if (entry) ThemeService.preview(entry.id)
        }
    }

    // ── Top row: the search pill, and the name of the theme that is showing ──
    SearchPill {
        id: search
        x: root.layout.padX
        y: root.layout.padTop
        pillHeight: root.layout.searchH
        expandedWidth: root.width - 2 * root.layout.padX
        pixelSize: root.layout.fontSize
        placeholder: "Search themes..."

        onTextChanged: ThemeService.query = text
        onKeyPressed: event => root.handleKey(event)
        onCollapsed: keys.forceActiveFocus()
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: root.layout.padX
        y: root.layout.padTop
        height: root.layout.searchH
        verticalAlignment: Text.AlignVCenter
        text: Theme.active.name
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
        opacity: search.expanded ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                duration: search.expanded ? Motion.fadeOut : Motion.fadeIn
                easing.type: Easing.OutCubic
            }
        }
    }

    // The thin line under the top row
    Rectangle {
        x: root.layout.padX
        y: root.layout.padTop + root.layout.searchH + root.layout.dividerGap
        width: root.width - 2 * root.layout.padX
        height: root.layout.dividerH
        color: Theme.border
    }

    // ── The cards: a row that slides so the highlighted card stays in the middle ──
    ListView {
        id: list
        x: 0
        y: root.listTop
        width: root.width
        height: root.layout.rowH
        orientation: ListView.Horizontal
        spacing: root.layout.cardGap
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ThemeService.results
        currentIndex: 0

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - root.layout.cardW) / 2
        preferredHighlightEnd: (width + root.layout.cardW) / 2
        highlightMoveDuration: Motion.carouselMs

        // A new search starts at the first card
        onModelChanged: currentIndex = 0

        // Resting on a card previews it
        onCurrentIndexChanged: if (root.visible) previewTimer.restart()

        delegate: Item {
            id: slot
            required property var modelData
            required property int index

            readonly property bool current: index === list.currentIndex

            width: root.layout.cardW
            height: list.height
            // The highlighted card grows over its neighbours
            z: current ? 1 : 0

            ThemeCard {
                anchors.centerIn: parent
                layout: root.layout
                entry: slot.modelData
                current: slot.current
                applied: slot.modelData.id === ThemeService.committedId

                onHovered: list.currentIndex = slot.index
                onChosen: {
                    list.currentIndex = slot.index
                    root.chooseCurrent()
                }
            }
        }
    }

    // Shown instead of the cards when nothing matches the search
    Text {
        x: list.x
        y: list.y
        width: list.width
        height: list.height
        visible: ThemeService.results.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "No themes found"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }

    // ── Under the cards: which theme out of how many ──
    Text {
        x: root.layout.padX
        y: root.height - root.layout.padBottom - root.layout.footerH
        width: root.width - 2 * root.layout.padX
        height: root.layout.footerH
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: ThemeService.results.length === 0
            ? "0/0"
            : (list.currentIndex + 1) + "/" + ThemeService.results.length
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
    }
}