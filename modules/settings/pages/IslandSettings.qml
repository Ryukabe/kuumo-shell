import ".."
import "../../../components"
import "../../.." as Root

// The Island page: the glow, how hovering opens the island, the keyboard, workspaces, music.
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

    SettingsCard {
        title: "Hover"

        SettingsRow {
            settingId: "island-hover-open"
            title: "Open delay"
            description: "How long to rest on the island before the extended panel opens."

            SettingsSlider {
                settingKey: "islandHoverOpenMs"
                from: 0; to: 1000; stepSize: 10; unit: "ms"
            }
        }

        SettingsRow {
            settingId: "island-hover-close"
            title: "Close delay"
            description: "How long the panel stays open after the pointer leaves. Longer is more forgiving."

            SettingsSlider {
                settingKey: "islandHoverCloseMs"
                from: 0; to: 2000; stepSize: 50; unit: "ms"
            }
        }
    }

    SettingsCard {
        title: "Keyboard"

        SettingsRow {
            settingId: "island-keyboard"
            title: "Take the keyboard while a panel is open"
            description: "Lets Esc close a panel. Off means Esc only works after you click the island."

            MoonToggle {
                checked: Root.Config.panelsTakeKeyboard
                onToggled: value => SettingsState.set("panelsTakeKeyboard", value)
            }
        }
    }

    SettingsCard {
        title: "Workspaces"

        SettingsRow {
            settingId: "island-workspaces-always"
            title: "Always shown"
            description: "This many workspace dots always show."

            SettingsSlider {
                settingKey: "workspacesAlwaysShown"
                iconName: "grid_view"
                from: 1; to: Root.Config.workspacesMax; stepSize: 1
            }
        }

        SettingsRow {
            settingId: "island-workspaces-max"
            title: "Most shown"
            description: "Later workspaces, up to this number, only show while they hold a window or are focused."

            SettingsSlider {
                settingKey: "workspacesMax"
                iconName: "grid_view"
                from: Root.Config.workspacesAlwaysShown; to: 10; stepSize: 1
            }
        }
    }

    SettingsCard {
        title: "Music player"

        SettingsRow {
            settingId: "island-media-scroll"
            title: "Scroll up skips to the next track"
            description: "Off means scrolling down is the next track."

            MoonToggle {
                checked: Root.Config.mediaScrollUpIsNext
                onToggled: value => SettingsState.set("mediaScrollUpIsNext", value)
            }
        }

        SettingsRow {
            settingId: "island-media-breathe"
            title: "Breathing divider"
            description: "The glow on the divider slowly breathes."

            MoonToggle {
                checked: Root.Config.mediaDividerBreathes
                onToggled: value => SettingsState.set("mediaDividerBreathes", value)
            }
        }

        SettingsRow {
            settingId: "island-media-surge"
            title: "Divider surge on track change"
            description: "The divider glow surges when the track changes."

            MoonToggle {
                checked: Root.Config.mediaDividerSurges
                onToggled: value => SettingsState.set("mediaDividerSurges", value)
            }
        }

        SettingsRow {
            settingId: "island-media-track-animation"
            title: "Track change animation"
            description: "The title and artist slide and the album art dips when the track changes."

            MoonToggle {
                checked: Root.Config.mediaTrackAnimation
                onToggled: value => SettingsState.set("mediaTrackAnimation", value)
            }
        }
    }
}