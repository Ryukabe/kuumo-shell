pragma Singleton
import QtQuick
import Quickshell
import "../../state"

// The actions of the power menu, and what each one runs.
Singleton {
    id: root

    // name is the label under the button, icon the icon-font name, hold means the
    // button must be held (Motion.holdMs) instead of tapped, ready: false means the
    // button is dimmed and does nothing yet.
    readonly property var actions: [
        { id: "lock",     name: "Lock",      icon: "lock",               hold: false, ready: false },
        { id: "sleep",    name: "Sleep",     icon: "bedtime",            hold: false, ready: true },
        { id: "logout",   name: "Log out",   icon: "logout",             hold: true,  ready: true },
        { id: "restart",  name: "Restart",   icon: "restart_alt",        hold: true,  ready: true },
        { id: "shutdown", name: "Shut down", icon: "power_settings_new", hold: true,  ready: true }
    ]

    // The command behind each action. Lock is not here until the Quickshell
    // lockscreen exists; add it with its id and set ready: true above.
    readonly property var commands: ({
        sleep:    ["systemctl", "suspend"],
        logout:   ["hyprctl", "dispatch", "exit"],
        restart:  ["systemctl", "reboot"],
        shutdown: ["systemctl", "poweroff"]
    })

    // Closes the island first (so it is not on screen when the machine wakes up),
    // then runs the command detached, so it still runs when the shell goes down.
    function run(id) {
        const cmd = root.commands[id]
        if (!cmd) return
        IslandState.closeAll()
        Quickshell.execDetached(cmd)
    }
}