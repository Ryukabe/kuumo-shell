import QtQuick
import "../../styles"

// A group of settings: an optional small title, then a rounded panel that holds the rows.
// Usage: SettingsCard { title: "Glow"; SettingsRow { ... } SettingsRow { ... } }
Item {
    id: root

    property string title: ""

    // Lets a row find the card it is in (see SettingsRow.cardTitle)
    readonly property bool isCard: true

    default property alias rows: column.data

    width: parent ? parent.width : 0
    height: panel.y + panel.height

    Text {
        id: heading
        x: SettingsLayout.rowPadX
        visible: root.title !== ""
        height: visible ? implicitHeight : 0
        text: root.title
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
        font.weight: Font.Medium
    }

    Rectangle {
        id: panel
        y: heading.visible ? heading.height + SettingsLayout.cardTitleGap : 0
        width: parent.width
        height: column.height + 2 * SettingsLayout.borderW
        radius: Theme.radiusSmall
        color: Theme.subBg
        border.width: SettingsLayout.borderW
        border.color: Theme.border

        Column {
            id: column
            x: SettingsLayout.borderW
            y: SettingsLayout.borderW
            width: parent.width - 2 * SettingsLayout.borderW
        }
    }
}