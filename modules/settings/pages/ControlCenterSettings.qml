import ".."
import "../../../components"
import "../../.." as Root

// The Control Center page: keyboard steps of the sliders, the volume and brightness keys,
// and the range of the Night Light.
SettingsPage {
    SettingsCard {
        title: "Sliders"

        SettingsRow {
            settingId: "control-slider-step"
            title: "Arrow key step"
            description: "How far a slider moves with the arrow keys once you have clicked it."
            keywords: "keyboard volume brightness"

            SettingsSlider {
                settingKey: "sliderStep"
                iconName: "keyboard"
                from: 0.005; to: 0.1; stepSize: 0.005; displayScale: 100; unit: "%"
            }
        }

        SettingsRow {
            settingId: "control-slider-large-step"
            title: "Large step"
            description: "Page Up, Page Down and Shift with the arrow keys."
            keywords: "keyboard page shift"

            SettingsSlider {
                settingKey: "sliderLargeStep"
                iconName: "keyboard"
                from: 0.05; to: 0.5; stepSize: 0.05; displayScale: 100; unit: "%"
            }
        }
    }

    SettingsCard {
        title: "Volume and brightness keys"

        SettingsRow {
            settingId: "control-volume-step"
            title: "Volume step"
            description: "How much one key press changes the volume."
            keywords: "keys osd"

            SettingsSlider {
                settingKey: "osdVolumeStep"
                iconName: "volume_up"
                from: 0.01; to: 0.2; stepSize: 0.01; displayScale: 100; unit: "%"
            }
        }

        SettingsRow {
            settingId: "control-volume-max"
            title: "Volume limit"
            description: "The loudest the keys and sliders go. Above 100% boosts the sound."
            keywords: "maximum boost loud osd"

            SettingsSlider {
                settingKey: "osdVolumeMax"
                iconName: "volume_up"
                from: 0.5; to: 1.5; stepSize: 0.05; displayScale: 100; unit: "%"
            }
        }

        SettingsRow {
            settingId: "control-brightness-step"
            title: "Brightness step"
            description: "How much one key press changes the brightness."
            keywords: "keys osd screen"

            SettingsSlider {
                settingKey: "osdBrightnessStep"
                iconName: "brightness_6"
                from: 1; to: 20; stepSize: 1; unit: "%"
            }
        }
    }

    SettingsCard {
        title: "Night Light temperature"

        SettingsRow {
            settingId: "control-nightlight-warmest"
            title: "Warmest"
            description: "The low end of the temperature slider."
            keywords: "night light kelvin orange"

            SettingsSlider {
                settingKey: "nightLightMinK"
                iconName: "thermostat"
                from: 1000; to: Root.Config.nightLightDefaultK; stepSize: 100; unit: "K"
            }
        }

        SettingsRow {
            settingId: "control-nightlight-coldest"
            title: "Coldest"
            description: "The high end of the temperature slider."
            keywords: "night light kelvin blue"

            SettingsSlider {
                settingKey: "nightLightMaxK"
                iconName: "thermostat"
                from: Root.Config.nightLightDefaultK; to: 10000; stepSize: 100; unit: "K"
            }
        }

        SettingsRow {
            settingId: "control-nightlight-default"
            title: "Starting temperature"
            description: "Used until you choose one."
            keywords: "night light kelvin default"

            SettingsSlider {
                settingKey: "nightLightDefaultK"
                iconName: "thermostat"
                from: Root.Config.nightLightMinK; to: Root.Config.nightLightMaxK; stepSize: 100; unit: "K"
            }
        }

        SettingsRow {
            settingId: "control-nightlight-step"
            title: "Slider step"
            description: "The temperature slider moves in steps of this."
            keywords: "night light kelvin"

            SettingsSlider {
                settingKey: "nightLightStepK"
                iconName: "thermostat"
                from: 10; to: 500; stepSize: 10; unit: "K"
            }
        }
    }

    SettingsCard {
        title: "Night Light dimming"

        SettingsRow {
            settingId: "control-nightlight-gamma-min"
            title: "Darkest"
            description: "The lowest the gamma slider goes."
            keywords: "night light gamma dim"

            SettingsSlider {
                settingKey: "nightLightMinGamma"
                iconName: "brightness_6"
                from: 10; to: Root.Config.nightLightMaxGamma; stepSize: 5; unit: "%"
            }
        }

        SettingsRow {
            settingId: "control-nightlight-gamma-max"
            title: "Brightest"
            description: "The highest the gamma slider goes."
            keywords: "night light gamma"

            SettingsSlider {
                settingKey: "nightLightMaxGamma"
                iconName: "brightness_6"
                from: Root.Config.nightLightMinGamma; to: 100; stepSize: 5; unit: "%"
            }
        }
    }
}   