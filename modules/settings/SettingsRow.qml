import QtQuick
import "../../styles"

// One setting: an optional icon, a title with a short description, and the control on the
// right. Whatever you put inside the row (a MoonToggle, a MoonDropdown, ...) is that control.
// Usage: SettingsRow { settingId: "halo"; title: "..."; description: "..."; MoonToggle { ... } }
Item {
    id: root

    // The id search uses to point at this row (it matches SettingsIndex's entry)
    property string settingId: ""
    property string title: ""
    property string description: ""
    // Optional Material Symbols name shown before the text
    property string icon: ""

    default property alias control: slot.data

    readonly property bool highlighted: root.settingId !== "" && SettingsNav.highlight === root.settingId

    width: parent ? parent.width : 0
    height: Math.max(SettingsLayout.rowH, texts.implicitHeight + 2 * SettingsLayout.rowPadY)

    // The page may open already pointing at this row, or the row may be pointed at later
    onHighlightedChanged: if (highlighted) flash.restart()
    Component.onCompleted: if (highlighted) flash.restart()

    // The line above the row (not on the first row of a card)
    Rectangle {
        width: parent.width
        height: SettingsLayout.borderW
        color: Theme.border
        opacity: root.y > 0 ? 1 : 0
    }

    // Lights up when search sends you here
    Rectangle {
        id: flashLayer
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.elevatedBg
        opacity: 0
    }

    SequentialAnimation {
        id: flash
        NumberAnimation {
            target: flashLayer; property: "opacity"; to: 1
            duration: Motion.hoverFade; easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: SettingsLayout.flashHoldMs }
        NumberAnimation {
            target: flashLayer; property: "opacity"; to: 0
            duration: SettingsLayout.flashFadeMs; easing.type: Easing.OutCubic
        }
    }

    Text {
        id: iconText
        x: SettingsLayout.rowPadX
        width: Theme.fontSizeLg
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== ""
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        color: Theme.fgMuted
        font.family: Theme.fontIcon
        font.pixelSize: Theme.fontSizeLg
    }

    Column {
        id: texts
        x: SettingsLayout.rowPadX + (root.icon !== "" ? iconText.width + SettingsLayout.iconGap : 0)
        width: slot.x - SettingsLayout.iconGap - x
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.title
            color: Theme.fg
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeSm
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.description !== ""
            text: root.description
            color: Theme.fgMuted
            font.family: Theme.fontText
            font.pixelSize: Theme.fontSizeXs
            wrapMode: Text.Wrap
        }
    }

    // The control, on the right
    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: SettingsLayout.rowPadX
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}