import Quickshell.Io
import "../../modules/settings"

// qs ipc call settings <function>
IpcHandler {
    target: "settings"

    // Open the Settings window, or close it again if it is open
    function toggle(): void { SettingsNav.toggle() }
    function open(): void { SettingsNav.show("") }
    function close(): void { SettingsNav.hide() }
    // Open the Settings window on one page, e.g. `qs ipc call settings openPage clipboard`
    function openPage(id: string): void { SettingsNav.show(id) }
}