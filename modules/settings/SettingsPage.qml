import QtQuick
import "../../components"
import "../../styles"

// The base of every settings page: the page title, then the page's content, scrolling when
// it is taller than the window. A page file is just `SettingsPage { ...cards... }`.
Item {
    id: root

    readonly property string title: SettingsNav.current.title

    default property alias content: body.data

    MoonFlickable {
        anchors.fill: parent
        contentHeight: body.y + body.height + SettingsLayout.pagePad

        Text {
            id: heading
            x: SettingsLayout.pagePad
            y: SettingsLayout.pagePad
            text: root.title
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: SettingsLayout.titleSize
            font.weight: Font.DemiBold
        }

        Column {
            id: body
            x: SettingsLayout.pagePad
            y: heading.y + heading.height + SettingsLayout.sectionGap
            width: root.width - 2 * SettingsLayout.pagePad
            spacing: SettingsLayout.sectionGap
        }
    }
}