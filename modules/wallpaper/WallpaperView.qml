pragma ComponentBehavior: Bound

import QtQuick
import "../.." as Root
import "../../components"
import "../../styles"
import "../../state"

// The wallpaper switcher island: the same design as the theme switcher. Top row: the island's
// clock and the name of the active theme on the left, the Static / Animated switch, and the
// search pill in the right corner (it pulls out to the left and pushes the switch along). Below
// it a row of wallpaper cards (the highlighted one bigger), and the count under that. Only the
// wallpapers of the active theme show. Resting on a card previews it
// (Config.switcherPreviewDelayMs). Enter or a click keeps it for the theme. Esc, a click outside
// or closing the island puts the kept one back. Left and right (or the pointer) move the
// highlight, Tab flips Static / Animated, and typing opens the search, where up and down move
// the highlight.
Item {
    id: root

    // Sizes from layouts.wallpaper in Island.qml, and how far the content has faded in (0..1)
    property var layout
    property real reveal: 0

    opacity: reveal
    visible: reveal > 0

    // Where the row of cards starts
    readonly property real listTop: layout.padTop + layout.searchH + layout.listGap

    // True while the cards are being replaced (a search, the Static / Animated switch), so
    // landing on the first card is not taken for you moving there
    property bool resetting: false

    // A fresh start whenever the island shows
    onVisibleChanged: if (visible) root.open()

    // No search, the mode of the wallpaper on screen, and that wallpaper highlighted
    function open() {
        search.collapse()
        WallpaperService.query = ""
        WallpaperService.animatedMode = WallpaperService.isAnimated(Root.Config.wallpaper)
        const index = Math.max(0, WallpaperService.indexOf(Root.Config.wallpaper))
        list.currentIndex = index
        list.positionViewAtIndex(index, ListView.Center)
        keys.forceActiveFocus()
    }

    function setMode(animated) { WallpaperService.animatedMode = animated }

    // Moves the highlight by `step` cards
    function move(step) {
        const last = WallpaperService.results.length - 1
        if (last < 0) return
        list.currentIndex = Math.max(0, Math.min(last, list.currentIndex + step))
    }

    // Keeps the highlighted wallpaper and closes the island
    function chooseCurrent() {
        const entry = WallpaperService.results[list.currentIndex]
        if (!entry) return
        previewTimer.stop()
        WallpaperService.commit(entry.name)
        IslandState.collapse()
    }

    // The keys of the island, from the key catcher below and from the search field
    function handleKey(event) {
        const searching = search.expanded
        const plain = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))

        if (event.key === Qt.Key_Tab) {
            root.setMode(!WallpaperService.animatedMode)
            event.accepted = true
        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Right && !searching)) {
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

    // Previews the highlighted wallpaper once you rest on it
    Timer {
        id: previewTimer
        interval: Root.Config.switcherPreviewDelayMs
        onTriggered: {
            const entry = WallpaperService.results[list.currentIndex]
            if (entry) WallpaperService.preview(entry.name)
        }
    }

    // ── Top row ──
    // The island's own clock sits at the far left (Island.qml moves it there); the name of the
    // theme these wallpapers belong to follows it, opening letter by letter whenever it changes
    // or the island opens, and stops short of the switch
    Item {
        x: root.layout.padX + root.layout.clockSlotW
        y: root.layout.padTop
        width: Math.max(0, modeSwitch.x - root.layout.gap - x)
        height: root.layout.searchH
        clip: true

        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.active.name
            playing: root.visible
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeSm
        }
    }

    // The search pill in the right corner
    SearchPill {
        id: search
        anchors.right: parent.right
        anchors.rightMargin: root.layout.padX
        y: root.layout.padTop
        pillHeight: root.layout.searchH
        expandedWidth: root.layout.searchExpandedW
        pixelSize: root.layout.fontSize
        placeholder: "Search wallpapers..."

        onTextChanged: WallpaperService.query = text
        onKeyPressed: event => root.handleKey(event)
        onCollapsed: keys.forceActiveFocus()
    }

    // Static / Animated: it sits against the pill's left edge, so the pill pushes it along as
    // it pulls out
    Rectangle {
        id: modeSwitch
        anchors.right: search.left
        anchors.rightMargin: root.layout.gap
        y: root.layout.padTop + (root.layout.searchH - root.layout.toggleH) / 2
        width: root.layout.toggleW
        height: root.layout.toggleH
        radius: Theme.radiusFull
        color: Theme.subBg

        // The highlight is stretched like rubber: its two edges are springs of different speed.
        // The edge it moves toward is quick and bouncy, the other edge follows slowly, so it
        // stretches out and then snaps together.
        Spring {
            id: edgeLeft
            target: WallpaperService.animatedMode
                ? modeSwitch.width / 2 + root.layout.toggleInset
                : root.layout.toggleInset
            response: WallpaperService.animatedMode ? Motion.rubberTrail.response : Motion.rubberLead.response
            dampingFraction: WallpaperService.animatedMode ? Motion.rubberTrail.damping : Motion.rubberLead.damping
            animated: !ShellState.motionReduced
        }
        Spring {
            id: edgeRight
            target: WallpaperService.animatedMode
                ? modeSwitch.width - root.layout.toggleInset
                : modeSwitch.width / 2 - root.layout.toggleInset
            response: WallpaperService.animatedMode ? Motion.rubberLead.response : Motion.rubberTrail.response
            dampingFraction: WallpaperService.animatedMode ? Motion.rubberLead.damping : Motion.rubberTrail.damping
            animated: !ShellState.motionReduced
        }
        Component.onCompleted: {
            edgeLeft.snap()
            edgeRight.snap()
        }

        Rectangle {
            x: edgeLeft.value
            y: root.layout.toggleInset
            width: Math.max(0, edgeRight.value - edgeLeft.value)
            height: modeSwitch.height - 2 * root.layout.toggleInset
            radius: Theme.radiusFull
            color: Theme.elevatedBg
        }

        Row {
            anchors.fill: parent

            Repeater {
                model: [
                    { label: "Static", animated: false },
                    { label: "Animated", animated: true }
                ]

                Item {
                    id: option
                    required property var modelData
                    width: modeSwitch.width / 2
                    height: modeSwitch.height

                    Text {
                        anchors.centerIn: parent
                        text: option.modelData.label
                        color: WallpaperService.animatedMode === option.modelData.animated
                            ? Theme.fg : Theme.fgMuted
                        Behavior on color { ColorAnimation { duration: Motion.hoverFade } }
                        font.family: Theme.fontText
                        font.pixelSize: Theme.fontSizeXs
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setMode(option.modelData.animated)
                    }
                }
            }
        }
    }

    // ── The cards: a row that slides so the highlighted card stays in the middle ──
    // The row is taller than the grown card, so its clip never touches a card
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
        model: WallpaperService.results
        currentIndex: 0

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - root.layout.cardW) / 2
        preferredHighlightEnd: (width + root.layout.cardW) / 2
        highlightMoveDuration: Motion.carouselMs

        // New cards (a search, the switch) start at the first one, without previewing it
        onModelChanged: {
            root.resetting = true
            currentIndex = 0
            root.resetting = false
        }

        // Resting on a card previews it
        onCurrentIndexChanged: if (root.visible && !root.resetting) previewTimer.restart()

        delegate: Item {
            id: slot
            required property var modelData
            required property int index

            readonly property bool current: index === list.currentIndex

            width: root.layout.cardW
            height: list.height
            // The highlighted card grows over its neighbours
            z: current ? 1 : 0

            WallpaperCard {
                anchors.centerIn: parent
                layout: root.layout
                entry: slot.modelData
                current: slot.current
                applied: slot.modelData.name === WallpaperService.savedName

                onHovered: list.currentIndex = slot.index
                onChosen: {
                    list.currentIndex = slot.index
                    root.chooseCurrent()
                }
            }
        }
    }

    // Shown instead of the cards when there is nothing to show
    Text {
        x: list.x
        y: list.y
        width: list.width
        height: list.height
        visible: WallpaperService.results.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: WallpaperService.entries.length === 0
            ? "No wallpapers listed for this theme"
            : "No " + (WallpaperService.animatedMode ? "animated" : "static") + " wallpapers found"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }

    // ── Under the cards: which wallpaper out of how many ──
    Text {
        x: root.layout.padX
        y: root.height - root.layout.padBottom - root.layout.footerH
        width: root.width - 2 * root.layout.padX
        height: root.layout.footerH
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: WallpaperService.results.length === 0
            ? "0/0"
            : (list.currentIndex + 1) + "/" + WallpaperService.results.length
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeXs
    }
}