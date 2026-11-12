pragma Singleton

import QtQuick
import ".."

// Wallpaper sync only. Color presets stay in styles/.
QtObject {
    readonly property string wallpaper: Config.wallpaper

    function sync(): void {
    }
}
