import Quickshell.Io
import "../../modules/osd"

// qs ipc call osd <function>: the volume and brightness keys
IpcHandler {
    target: "osd"

    function volumeUp(): void { OsdService.volumeUp() }
    function volumeDown(): void { OsdService.volumeDown() }
    function volumeMute(): void { OsdService.volumeMute() }
    function brightnessUp(): void { OsdService.brightnessUp() }
    function brightnessDown(): void { OsdService.brightnessDown() }
}