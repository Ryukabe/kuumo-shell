import QtQuick
import "../../components"
import "../.." as Root

// A number setting as a MoonSlider. It reads the setting from Config.qml, turns the slider's
// 0..1 into a value between `from` and `to` (in steps of `stepSize`), and saves it through
// SettingsState. Usage:
//   SettingsSlider { settingKey: "islandHoverOpenMs"; from: 0; to: 1000; stepSize: 10; unit: "ms" }
MoonSlider {
    id: root

    // The Config.qml property this slider changes (it must be in SettingsState.keys)
    required property string settingKey
    property real from: 0
    property real to: 1
    property real stepSize: 1
    property string unit: ""

    readonly property real current: Root.Config[root.settingKey]
    readonly property real span: root.to - root.from

    width: SettingsLayout.sliderW
    layout: SettingsLayout.sliderLayout
    iconName: "timer"
    level: root.span > 0 ? Math.max(0, Math.min(1, (root.current - root.from) / root.span)) : 0
    valueText: root.current + (root.unit !== "" ? " " + root.unit : "")
    // Keyboard steps: one step, and five steps for the large one
    step: root.span > 0 ? root.stepSize / root.span : 0.01
    largeStep: root.span > 0 ? Math.min(1, 5 * root.stepSize / root.span) : 0.1

    onMoved: value => {
        const raw = root.from + value * root.span
        const snapped = Math.round((raw - root.from) / root.stepSize) * root.stepSize + root.from
        SettingsState.set(root.settingKey, Math.max(root.from, Math.min(root.to, snapped)))
    }
}