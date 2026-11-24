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

        SettingsRow {
            settingId: "launcher-group-max"
            title: "Results per group"
            description: "How many apps, commands, settings and files each show for what you type."
            keywords: "results group limit count"

            SettingsSlider {
                settingKey: "launcherGroupMax"
                iconName: "list"
                from: 3; to: 10; stepSize: 1; unit: "results"
            }
        }

        SettingsRow {
            settingId: "launcher-headers"
            configKey: "launcherHeaders"
            title: "Section titles"
            description: "Shows a small title (Apps, Settings, Files, ...) above each group of results."
            keywords: "headers groups labels"

            MoonToggle {
                checked: Root.Config.launcherHeaders
                onToggled: value => SettingsState.set("launcherHeaders", value)
            }
        }
    }

    SettingsCard {
        title: "Search"

        SettingsRow {
            settingId: "launcher-source-apps"
            configKey: "launcherSourceApps"
            title: "Apps"
            description: "Search your installed apps."
            keywords: "applications programs launch"

            MoonToggle {
                checked: Root.Config.launcherSourceApps
                onToggled: value => SettingsState.set("launcherSourceApps", value)
            }
        }

        SettingsRow {
            settingId: "launcher-source-commands"
            configKey: "launcherSourceCommands"
            title: "Commands"
            description: "Find commands like the emoji picker or the power menu without typing >."
            keywords: "emoji power clipboard theme wallpaper"

            MoonToggle {
                checked: Root.Config.launcherSourceCommands
                onToggled: value => SettingsState.set("launcherSourceCommands", value)
            }
        }

        SettingsRow {
            settingId: "launcher-source-settings"
            configKey: "launcherSourceSettings"
            title: "Settings"
            description: "Find settings and change them from the launcher: a toggle flips with Enter, a slider moves with the arrow keys."
            keywords: "options preferences change toggle"

            MoonToggle {
                checked: Root.Config.launcherSourceSettings
                onToggled: value => SettingsState.set("launcherSourceSettings", value)
            }
        }

        SettingsRow {
            settingId: "launcher-source-files"
            configKey: "launcherSourceFiles"
            title: "Files"
            description: "Find files and folders on the disk with fd. Enter opens one, Ctrl+Enter shows it in its folder."
            keywords: "documents folders disk find fd"

            MoonToggle {
                checked: Root.Config.launcherSourceFiles
                onToggled: value => SettingsState.set("launcherSourceFiles", value)
            }
        }

        SettingsRow {
            settingId: "launcher-source-web"
            configKey: "launcherSourceWeb"
            title: "Web search"
            description: "Shows a row at the end of the results that searches the web for what you typed."
            keywords: "internet google browser"

            MoonToggle {
                checked: Root.Config.launcherSourceWeb
                onToggled: value => SettingsState.set("launcherSourceWeb", value)
            }
        }
    }

    SettingsCard {
        title: "Files"

        SettingsRow {
            settingId: "launcher-files-where"
            configKey: "launcherFilesWhere"
            title: "Where to look"
            description: "The whole home folder, or only the usual folders (Documents, Downloads, Desktop, Pictures, Videos and Music), which is faster."
            keywords: "folders home directory search path"

            MoonDropdown {
                options: [
                    { value: "home", label: "Home folder" },
                    { value: "common", label: "Usual folders" }
                ]
                value: Root.Config.launcherFilesWhere
                onPicked: value => SettingsState.set("launcherFilesWhere", value)
            }
        }

        SettingsRow {
            settingId: "launcher-files-hidden"
            configKey: "launcherFilesHidden"
            title: "Include hidden files"
            description: "Also finds files and folders whose name starts with a dot."
            keywords: "dotfiles config hidden"

            MoonToggle {
                checked: Root.Config.launcherFilesHidden
                onToggled: value => SettingsState.set("launcherFilesHidden", value)
            }
        }
    }

    SettingsCard {
        title: "Web"

        SettingsRow {
            settingId: "launcher-web-engine"
            configKey: "launcherWebEngine"
            title: "Search engine"
            description: "Which search engine the web search row uses."
            keywords: "duckduckgo google brave startpage browser"

            MoonDropdown {
                options: [
                    { value: "duckduckgo", label: "DuckDuckGo" },
                    { value: "google", label: "Google" },
                    { value: "brave", label: "Brave Search" },
                    { value: "startpage", label: "Startpage" }
                ]
                value: Root.Config.launcherWebEngine
                onPicked: value => SettingsState.set("launcherWebEngine", value)
            }
        }
    }

    SettingsCard {
        title: "Answers"

        SettingsRow {
            settingId: "launcher-calculator"
            configKey: "launcherCalculator"
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
            configKey: "launcherSuggestions"
            title: "Conversion suggestions"
            description: "While you type a number or a unit, offers ways to finish the conversion."
            keywords: "convert autocomplete hints"

            MoonToggle {
                checked: Root.Config.launcherSuggestions
                onToggled: value => SettingsState.set("launcherSuggestions", value)
            }
        }
    }

    SettingsCard {
        title: "Commands"

        SettingsRow {
            settingId: "launcher-backspace-leaves"
            configKey: "launcherBackspaceLeavesCommands"
            title: "Backspace leaves the command list"
            description: "Backspace on an empty search field in the command list goes back to the apps. Off keeps you in the commands; Esc still closes the island."
            keywords: "back return apps empty esc"

            MoonToggle {
                checked: Root.Config.launcherBackspaceLeavesCommands
                onToggled: value => SettingsState.set("launcherBackspaceLeavesCommands", value)
            }
        }
    }
}