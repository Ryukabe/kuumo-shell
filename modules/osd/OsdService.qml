pragma Singleton

import QtQuick
import "../../state"

QtObject {
    function reveal(kind: string): void {
        SystemState.osdKind = kind
        SystemState.osdVisible = true
    }

    function dismiss(): void {
        SystemState.osdVisible = false
    }
}
