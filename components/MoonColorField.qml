import QtQuick
import "../styles"

// A color as hex text (#rrggbb) with a swatch. It says picked(value) only for a complete, valid
// color, so a half-typed one never reaches the setting; the border goes red meanwhile.
Item {
    id: root

    // The color as "#rrggbb"
    property string value: "#000000"

    // Sizes; the defaults suit a settings row
    property int controlWidth: 140
    property int controlHeight: 34
    property int padX: 10
    property int swatchSize: 16
    property int borderWidth: 1
    property real disabledOpacity: 0.4

    signal picked(string value)

    readonly property bool valid: /^#[0-9a-fA-F]{6}$/.test(input.text)

    implicitWidth: root.controlWidth
    implicitHeight: root.controlHeight
    opacity: root.enabled ? 1 : root.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.elevatedBg
        border.width: root.borderWidth
        border.color: !root.valid ? Theme.red : input.activeFocus ? Theme.fgMuted : Theme.border
        Behavior on border.color { ColorAnimation { duration: Motion.hoverFade } }
    }

    Rectangle {
        id: swatch
        x: root.padX
        anchors.verticalCenter: parent.verticalCenter
        width: root.swatchSize
        height: root.swatchSize
        radius: width / 2
        color: root.valid ? input.text : root.value
        border.width: 1
        border.color: Theme.border
    }

    TextInput {
        id: input
        anchors.left: swatch.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: root.padX
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSizeSm
        maxLength: 7
        selectByMouse: true
        clip: true

        onTextEdited: {
            if (/^#[0-9a-fA-F]{6}$/.test(input.text)) root.picked(input.text.toLowerCase())
        }
        // Leaving the field with half a color puts the real one back
        onEditingFinished: if (!root.valid) input.text = root.value
    }

    // The text follows the value, except while you are typing in it
    Binding {
        target: input
        property: "text"
        value: root.value
        when: !input.activeFocus
    }
}