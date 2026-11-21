import ".."
import "../../../components"

// Temporary demo of the settings components; step 3 replaces it with real settings
SettingsPage {
    id: page

    property bool demoOn: true
    property string demoPick: "b"

    SettingsCard {
        title: "Demo"

        SettingsRow {
            settingId: "demo-toggle"
            title: "Demo toggle"
            description: "Flips a plain property. Nothing is saved yet."
            MoonToggle {
                checked: page.demoOn
                onToggled: value => page.demoOn = value
            }
        }

        SettingsRow {
            settingId: "demo-pick"
            title: "Demo dropdown"
            description: "Picks one of three options."
            MoonDropdown {
                options: [
                    { value: "a", label: "Option A" },
                    { value: "b", label: "Option B" },
                    { value: "c", label: "Option C" }
                ]
                value: page.demoPick
                onPicked: value => page.demoPick = value
            }
        }
    }
}