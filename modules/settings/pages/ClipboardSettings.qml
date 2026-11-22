import ".."
import "../../.." as Root

// The Clipboard page.
SettingsPage {
    SettingsCard {
        title: "Copying"

        SettingsRow {
            settingId: "clipboard-close-delay"
            title: "Close delay after copying"
            description: "How long the clipboard island stays open after a copy, so you can see \"Copied\"."

            SettingsSlider {
                settingKey: "clipboardCopyCloseMs"
                iconName: "content_paste"
                from: 0; to: 3000; stepSize: 100; unit: "ms"
            }
        }
    }
}