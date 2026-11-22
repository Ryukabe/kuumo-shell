import ".."
import "../../../components"
import "../../.." as Root

// The Appearance page: wallpaper changes, the switchers, text effects.
// The theme and wallpaper pickers go at the top later.
SettingsPage {
    id: page

    // Transition types of `awww img`; the first letter is capitalised for the label
    readonly property var transitions: [
        "none", "simple", "fade", "left", "right", "top", "bottom",
        "wipe", "wave", "grow", "center", "any", "outer", "random"
    ].map(name => ({ value: name, label: name.charAt(0).toUpperCase() + name.slice(1) }))

    SettingsCard {
        title: "Wallpaper changes"

        SettingsRow {
            settingId: "appearance-wallpaper-transition"
            title: "Transition"
            description: "How the screen changes when you keep a wallpaper."
            keywords: "awww animation effect"

            MoonDropdown {
                options: page.transitions
                value: Root.Config.wallpaperTransition
                onPicked: value => SettingsState.set("wallpaperTransition", value)
            }
        }

        SettingsRow {
            settingId: "appearance-wallpaper-preview-transition"
            title: "Preview transition"
            description: "Used for previews, theme changes in the switcher and the wallpaper restored at startup. None finishes instantly."
            keywords: "awww animation effect"

            MoonDropdown {
                options: page.transitions
                value: Root.Config.wallpaperPreviewTransition
                onPicked: value => SettingsState.set("wallpaperPreviewTransition", value)
            }
        }

        SettingsRow {
            settingId: "appearance-wallpaper-duration"
            title: "Transition length"
            description: "Does not apply to the Simple transition."
            keywords: "seconds duration speed"

            SettingsSlider {
                settingKey: "wallpaperTransitionSeconds"
                iconName: "wallpaper"
                from: 0.2; to: 3; stepSize: 0.1; unit: "s"
            }
        }

        SettingsRow {
            settingId: "appearance-wallpaper-fps"
            title: "Transition frame rate"
            description: "Higher is smoother but uses more power."
            keywords: "fps smooth"

            SettingsSlider {
                settingKey: "wallpaperTransitionFps"
                iconName: "speed"
                from: 15; to: 144; stepSize: 1; unit: "fps"
            }
        }
    }

    SettingsCard {
        title: "Switchers"

        SettingsRow {
            settingId: "appearance-preview-delay"
            title: "Preview delay"
            description: "Resting on a theme or wallpaper card this long applies it as a preview, so scrolling fast does not apply every card."
            keywords: "theme wallpaper switcher hover"

            SettingsSlider {
                settingKey: "switcherPreviewDelayMs"
                iconName: "preview"
                from: 0; to: 600; stepSize: 10; unit: "ms"
            }
        }
    }

    SettingsCard {
        title: "Text"

        SettingsRow {
            settingId: "appearance-typewriter"
            title: "Text effects"
            description: "Typing, backspace and iris effects. Off shows the final text at once."
            keywords: "typewriter animation typing"

            MoonToggle {
                checked: Root.Config.typewriter
                onToggled: value => SettingsState.set("typewriter", value)
            }
        }
    }
    
    SettingsCard {
        title: "Adding wallpapers"

        SettingsRow {
            settingId: "appearance-wallpaper-drop"
            title: "Add by dropping"
            description: "Drag image files onto the island to copy them into the wallpapers folder and add them to the current theme."
            keywords: "drag drop add import wallpaper folder"

            MoonToggle {
                checked: Root.Config.wallpaperDropEnabled
                onToggled: value => SettingsState.set("wallpaperDropEnabled", value)
            }
        }

        SettingsRow {
            settingId: "appearance-wallpaper-drop-all"
            title: "Right half adds to every theme"
            description: "While dragging, the right half of the island adds the files to all themes, and the left half only to the current one."
            keywords: "drag drop all themes every"

            MoonToggle {
                checked: Root.Config.wallpaperDropAllThemes
                onToggled: value => SettingsState.set("wallpaperDropAllThemes", value)
            }
        }

        SettingsRow {
            settingId: "appearance-wallpaper-drop-delay"
            title: "Open delay"
            description: "How long a dragged image must rest on the island before the switcher opens. 0 opens at once."
            keywords: "drag drop wait hover accidental delay"

            SettingsSlider {
                settingKey: "wallpaperDropOpenMs"
                iconName: "timer"
                from: 0; to: 1500; stepSize: 50; unit: "ms"
            }
        }
    }
}