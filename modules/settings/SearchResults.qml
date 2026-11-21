pragma ComponentBehavior: Bound

import QtQuick
import "../../styles"

// The results under the search field. Hovering or Up/Down picks one; Enter or a click opens it.
Item {
    id: root

    property string query: ""
    readonly property var results: SettingsIndex.search(root.query)

    // A result was opened (the field can clear itself)
    signal opened()

    function next() { list.incrementCurrentIndex() }
    function previous() { list.decrementCurrentIndex() }

    function openCurrent() {
        const entry = root.results[list.currentIndex]
        if (!entry) return
        SettingsNav.openEntry(entry)
        root.opened()
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        spacing: SettingsLayout.itemGap
        boundsBehavior: Flickable.StopAtBounds
        model: root.results
        currentIndex: 0

        // A new search starts at the top
        onModelChanged: currentIndex = 0

        delegate: SearchResultRow {
            required property var modelData
            required property int index

            entry: modelData
            width: list.width
            highlighted: index === list.currentIndex
            onHovered: list.currentIndex = index
            onClicked: {
                list.currentIndex = index
                root.openCurrent()
            }
        }
    }

    Text {
        width: parent.width
        height: SettingsLayout.resultH
        visible: root.results.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "No results"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }
}