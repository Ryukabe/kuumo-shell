pragma ComponentBehavior: Bound

import QtQuick

// The content of the power menu: one row of round buttons, one slot each, label
// underneath. Island.qml places it and drives `reveal`.
Item {
    id: root

    // The power layout block from Island.qml
    required property var layout
    // 0..1, how far the power content has appeared (from Island.qml)
    required property real reveal

    opacity: reveal
    visible: reveal > 0
    // Only takes input once it is mostly visible
    enabled: reveal > 0.5

    // The width of one button slot
    readonly property real slotW: (layout.w - 2 * layout.padX) / layout.slots

    Row {
        x: root.layout.padX
        y: root.layout.padTop

        Repeater {
            model: PowerService.actions

            delegate: PowerButton {
                required property var modelData

                layout: root.layout
                width: root.slotW
                label: modelData.name
                iconName: modelData.icon
                hold: modelData.hold
                ready: modelData.ready
                onActivated: PowerService.run(modelData.id)
            }
        }
    }
}