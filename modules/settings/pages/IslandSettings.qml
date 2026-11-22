import ".."
import "../../../components"
import "../../.." as Root

// The Island page. More cards go below the first one.
SettingsPage {
    SettingsCard {
        title: "Glow"

        SettingsRow {
            settingId: "island-halo"
            title: "Moonlight halo"
            description: "A soft glow behind the island."

            MoonToggle {
                checked: Root.Config.islandHalo
                onToggled: value => SettingsState.set("islandHalo", value)
            }
        }
    }
}