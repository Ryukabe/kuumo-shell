import ".."
import "../../.." as Root

// The Notifications page.
SettingsPage {
    SettingsCard {
        title: "Toasts"

        SettingsRow {
            settingId: "notifications-toast-time"
            title: "Toast time"
            description: "How long a notification stays on the island."

            SettingsSlider {
                settingKey: "notificationToastMs"
                iconName: "notifications"
                from: 1000; to: 15000; stepSize: 500; unit: "ms"
            }
        }
    }
}