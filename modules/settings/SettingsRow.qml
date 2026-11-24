import QtQuick
import "../../styles"

// One setting: an optional icon, a title with a short description, and the control on the
// right. Whatever you put inside the row (a MoonToggle, a MoonDropdown, ...) is that control.
// A row with a settingId is found by search on its own; no list needs updating.
// A row whose control changes a Config setting can also be changed from the launcher: a
// SettingsSlider already says which setting it changes; a toggle or a dropdown needs
// configKey on the row.
// Usage: SettingsRow { settingId: "halo"; configKey: "islandHalo"; title: "..."; description: "..."; MoonToggle { ... } }
Item {
    id: root

    // The id search uses to point at this row. Without one the row is not searchable.
    // It must be unique across all pages.
    property string settingId: ""
    property string title: ""
    property string description: ""
    // Optional extra words that should find this row in the search ("shadow light")
    property string keywords: ""
    // Optional Material Symbols name shown before the text
    property string icon: ""
    // The Config.qml property this row's control changes (must be in SettingsState.keys).
    // Not needed for a SettingsSlider, which says it itself.
    property string configKey: ""
    // False keeps the row out of the launcher (for a slider whose range depends on another setting)
    property bool inLauncher: true

    default property alias control: slot.data

    readonly property bool highlighted: root.settingId !== "" && SettingsNav.highlight === root.settingId

    // The title of the SettingsCard this row sits in
    function cardTitle() {
        let item = root.parent
        while (item) {
            if (item.isCard) return item.title
            item = item.parent
        }
        return ""
    }

    // What the launcher needs to change this setting, or null when it cannot be changed there:
    //   { key, kind: "toggle" }
    //   { key, kind: "number", from, to, step, unit, scale }
    //   { key, kind: "choice", options: [{ value, label }] }
    //   { key, kind: "color" }
    function controlInfo() {
        if (!root.inLauncher) return null
        const child = slot.children.length > 0 ? slot.children[0] : null
        let key = root.configKey
        if (key === "" && child && child.settingKey !== undefined) key = child.settingKey
        if (key === "") return null

        SettingsState.captureDefaults()
        const base = SettingsState.defaults[key]
        if (base === undefined) return null

        if (typeof base === "boolean") return { key: key, kind: "toggle" }

        if (typeof base === "number") {
            if (!child || child.from === undefined || child.to === undefined) return null
            return {
                key: key, kind: "number",
                from: child.from, to: child.to,
                step: child.stepSize !== undefined ? child.stepSize : 1,
                unit: child.unit !== undefined ? child.unit : "",
                scale: child.displayScale !== undefined ? child.displayScale : 1
            }
        }

        if (typeof base === "string") {
            if (child && child.options !== undefined) return { key: key, kind: "choice", options: child.options }
            if (child && child.valid !== undefined) return { key: key, kind: "color" }
        }
        return null
    }

    width: parent ? parent.width : 0
    height: Math.max(SettingsLayout.rowH, texts.implicitHeight + 2 * SettingsLayout.rowPadY)

    // The page may open already pointing at this row, or the row may be pointed at later
    onHighlightedChanged: if (highlighted) flash.restart()

    Component.onCompleted: {
        // While SettingsIndex builds the pages to collect their rows, report this one
        if (SettingsIndex.scanning && root.settingId !== "") {
            SettingsIndex.register({
                id: root.settingId,
                title: root.title,
                description: root.description,
                section: root.cardTitle(),
                keywords: root.keywords,
                control: root.controlInfo()
            })
        }
        if (highlighted) flash.restart()
    }

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