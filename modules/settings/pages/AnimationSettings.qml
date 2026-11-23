import ".."
import "../../../components"
import "../../.." as Root

// The Animations page: reduced motion, how fast things move, and how much they bounce.
SettingsPage {
    SettingsCard {
        title: "Motion"

        SettingsRow {
            settingId: "animations-reduce"
            title: "Reduce motion"
            description: "Turns animations off: things jump to where they are going and fades are instant."
            keywords: "animations off disable accessibility motion"

            MoonToggle {
                checked: Root.Config.reduceMotion
                onToggled: value => SettingsState.set("reduceMotion", value)
            }
        }

        SettingsRow {
            settingId: "animations-speed"
            title: "Animation speed"
            description: "How fast the island, the switchers and the fades move. Above 1x is faster, below 1x is slower."
            keywords: "motion fast slow duration smooth"

            SettingsSlider {
                settingKey: "animationSpeed"
                iconName: "speed"
                from: 0.25; to: 2; stepSize: 0.05; unit: "x"
            }
        }
    }

    SettingsCard {
        title: "Bounce"

        SettingsRow {
            settingId: "animations-bounce"
            title: "Island bounce"
            description: "How much the island overshoots when it opens and closes. 0% settles without bounce; 50% is the original feel."
            keywords: "spring overshoot morph damping"

            SettingsSlider {
                settingKey: "islandBounce"
                iconName: "animation"
                from: 0; to: 1; stepSize: 0.05; displayScale: 100; unit: "%"
            }
        }

        SettingsRow {
            settingId: "animations-osd-bounce"
            title: "Volume and brightness bounce"
            description: "How much the bar overshoots when the level changes. 100% is the original feel."
            keywords: "osd spring overshoot volume brightness"

            SettingsSlider {
                settingKey: "osdBounce"
                iconName: "volume_up"
                from: 0; to: 1; stepSize: 0.05; displayScale: 100; unit: "%"
            }
        }

        SettingsRow {
            settingId: "animations-switcher-bounce"
            title: "Switcher card bounce"
            description: "How much a theme or wallpaper card springs when it is highlighted. 50% is the original feel."
            keywords: "theme wallpaper card spring grow overshoot"

            SettingsSlider {
                settingKey: "switcherBounce"
                iconName: "animation"
                from: 0; to: 1; stepSize: 0.05; displayScale: 100; unit: "%"
            }
        }
    }

    SettingsCard {
        title: "Clock"

        SettingsRow {
            settingId: "animations-clock-roll"
            title: "Rolling digits"
            description: "The clock's digits roll when the time changes. Off changes them at once."
            keywords: "clock digit number flow roll time"

            MoonToggle {
                checked: Root.Config.clockRoll
                onToggled: value => SettingsState.set("clockRoll", value)
            }
        }
    }

    SettingsCard {
        title: "Scrolling"

        SettingsRow {
            settingId: "animations-scroll-step"
            title: "Scroll distance"
            description: "How far one notch of the mouse wheel scrolls the lists in Settings."
            keywords: "mouse wheel speed smooth"

            SettingsSlider {
                settingKey: "scrollStep"
                iconName: "swap_vert"
                from: 30; to: 240; stepSize: 10; unit: "px"
            }
        }

        SettingsRow {
            settingId: "animations-scroll-bounce"
            title: "Scroll bounce"
            description: "How far a list can be pulled past its top or bottom before it settles back. 0 turns the bounce off."
            keywords: "overscroll rubber band edge"

            SettingsSlider {
                settingKey: "scrollBounce"
                iconName: "swap_vert"
                from: 0; to: 80; stepSize: 5; unit: "px"
            }
        }
    }
}