import QtQuick
import ".."
import "../../../components"
import "../../../styles"
import "../../theme"
import "../../.." as Root

// The Appearance page: wallpaper changes, the switchers, text effects.
// The theme and wallpaper pickers go at the top later.
SettingsPage {
    id: page

    // Copies a theme's colors into the custom theme
    function copyPreset(id) {
        const preset = Theme.presetMap[id]
        if (!preset) return
        SettingsState.set("customDarkMode", preset.darkMode)
        SettingsState.set("customBg", String(preset.bg))
        SettingsState.set("customSubBg", String(preset.subBg))
        SettingsState.set("customElevatedBg", String(preset.elevatedBg))
        SettingsState.set("customBorder", String(preset.border))
        SettingsState.set("customFgMuted", String(preset.fgMuted))
        SettingsState.set("customFg", String(preset.fg))
        SettingsState.set("customAccent", String(preset.accent))
        SettingsState.set("customRed", String(preset.red))
        SettingsState.set("customGreen", String(preset.green))
        SettingsState.set("customYellow", String(preset.yellow))
        SettingsState.set("customBlue", String(preset.blue))
        SettingsState.set("customPurple", String(preset.purple))
        SettingsState.set("customCyan", String(preset.cyan))
    }

    SettingsCard {
        title: "Theme"

        SettingsRow {
            settingId: "appearance-theme-source"
            title: "Theme source"
            description: "Use one of the themes, make the colors from the wallpaper on screen, or set your own. Choosing a theme in the theme switcher goes back to Themes."
            keywords: "colors preset wallpaper custom dynamic material you"

            MoonSegmented {
                options: [
                    { value: "preset", label: "Themes" },
                    { value: "wallpaper", label: "Wallpaper" },
                    { value: "custom", label: "Custom" }
                ]
                value: ThemeService.source
                onPicked: value => ThemeService.setSource(value)
            }
        }
    }

    SettingsCard {
        title: "Custom theme"
        visible: ThemeService.source === "custom"

        SettingsRow {
            settingId: "appearance-custom-copy"
            title: "Start from a theme"
            description: "Copies that theme's colors into the fields below."
            keywords: "custom copy preset base"

            MoonDropdown {
                options: [{ value: "", label: "Choose a theme" }].concat(
                    ThemeService.themes.map(t => ({ value: t.id, label: t.name })))
                value: ""
                onPicked: id => { if (id !== "") page.copyPreset(id) }
            }
        }

        SettingsRow {
            settingId: "appearance-custom-dark"
            title: "Dark theme"
            description: "Tell apps whether this theme is dark or light."
            keywords: "custom light dark mode"

            MoonToggle {
                checked: Root.Config.customDarkMode
                onToggled: value => SettingsState.set("customDarkMode", value)
            }
        }

        Repeater {
            model: [
                { key: "customBg", label: "Background", note: "The main background." },
                { key: "customSubBg", label: "Surface", note: "The island and cards." },
                { key: "customElevatedBg", label: "Raised surface", note: "Pills, hover and popups." },
                { key: "customBorder", label: "Border", note: "Lines and outlines." },
                { key: "customFg", label: "Text", note: "The main text." },
                { key: "customFgMuted", label: "Muted text", note: "Secondary text and icons." },
                { key: "customAccent", label: "Accent", note: "Highlights and the moon." },
                { key: "customRed", label: "Red", note: "" },
                { key: "customGreen", label: "Green", note: "" },
                { key: "customYellow", label: "Yellow", note: "" },
                { key: "customBlue", label: "Blue", note: "" },
                { key: "customPurple", label: "Purple", note: "" },
                { key: "customCyan", label: "Cyan", note: "" }
            ]

            delegate: SettingsRow {
                id: colorRow
                required property var modelData

                settingId: "appearance-" + colorRow.modelData.key
                title: colorRow.modelData.label
                description: colorRow.modelData.note
                keywords: "custom color hex theme"

                MoonColorField {
                    value: Root.Config[colorRow.modelData.key]
                    onPicked: value => SettingsState.set(colorRow.modelData.key, value)
                }
            }
        }
    }

    // Transition types of `awww img`; the first letter is capitalised for the label
    readonly property var transitionOptions: [
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
                options: page.transitionOptions
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
                options: page.transitionOptions
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