import ".."
import "../../../components"
import "../../.." as Root

// The Launcher page.
SettingsPage {
    SettingsCard {
        title: "List"

        SettingsRow {
            settingId: "launcher-max-rows"
            title: "Rows shown"
            description: "How many results show before the list scrolls."
            keywords: "results height size"

            SettingsSlider {
                settingKey: "launcherMaxRows"
                iconName: "list"
                from: 3; to: 12; stepSize: 1; unit: "rows"
            }
        }
    }

    SettingsCard {
        title: "Answers"

        SettingsRow {
            settingId: "launcher-calculator"
            title: "Calculator and unit answers"
            description: "Typing a sum or a conversion shows the answer on top. Enter copies it."
            keywords: "math convert currency units"

            MoonToggle {
                checked: Root.Config.launcherCalculator
                onToggled: value => SettingsState.set("launcherCalculator", value)
            }
        }

        SettingsRow {
            settingId: "launcher-suggestions"
            title: "Conversion suggestions"
            description: "While you type a number or a unit, offers ways to finish the conversion."
            keywords: "convert autocomplete hints"

            MoonToggle {
                checked: Root.Config.launcherSuggestions
                onToggled: value => SettingsState.set("launcherSuggestions", value)
            }
        }
    }
}