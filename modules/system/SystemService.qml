pragma Singleton

import QtQuick
import "../../state"

// Writes volume, mute, and brightness into SystemState.
QtObject {
    function showVolume(value: real): void {
        SystemState.volume = value
        SystemState.osdKind = "volume"
        SystemState.osdVisible = true
    }

    function showBrightness(value: real): void {
        SystemState.brightness = value
        SystemState.osdKind = "brightness"
        SystemState.osdVisible = true
    }
}
