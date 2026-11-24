import ".."
import "../../../components"
import "../../.." as Root

// The Clipboard page.
SettingsPage {
    SettingsCard {
        title: "Choosing an item"

        SettingsRow {
            settingId: "clipboard-auto-paste"
            configKey: "clipboardAutoPaste"
            title: "Paste into the window you were in"
            description: "Also pastes the item after copying it. Needs wtype installed. Pictures only paste into apps that accept them."
            keywords: "paste insert type automatic wtype"

            MoonToggle {
                checked: Root.Config.clipboardAutoPaste
                onToggled: value => SettingsState.set("clipboardAutoPaste", value)
            }
        }

        SettingsRow {
            settingId: "clipboard-close-delay"
            title: "Close delay after copying"
            description: "How long the island stays open after a copy, so you can see \"Copied\". With pasting on, a short delay feels better."
            keywords: "copied wait"

            SettingsSlider {
                settingKey: "clipboardCopyCloseMs"
                iconName: "content_paste"
                from: 0; to: 3000; stepSize: 100; unit: "ms"
            }
        }
    }
}