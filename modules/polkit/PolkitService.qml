pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import "../../state"

// The polkit agent. It opens the polkit island by itself when something asks for
// authentication, and cancels the request when the island is closed (ESC, a click
// outside, or another island opening).
Singleton {
    id: root

    // Island.qml reads this once, so the agent registers when the shell starts
    readonly property bool started: true
    // Whether our agent got registered (a second agent running would stop it)
    readonly property bool registered: agent.isRegistered
    readonly property bool active: agent.isActive

    // What the prompt shows. Kept after the request ends so the text does not
    // vanish while the island fades out.
    property string message: ""
    property string actionId: ""
    property string userName: ""

    // True after a wrong password, until you type again
    property bool wrong: false
    // Fired once per wrong password (the view shakes its field)
    signal wrongPassword()

    function submit(password) {
        if (agent.flow && password.length > 0) {
            root.wrong = false
            agent.flow.submit(password)
        }
    }

    function clearError() { root.wrong = false }

    // Cancel the open request, if there is one
    function cancel() {
        const f = agent.flow
        if (f && !f.isCompleted) f.cancelAuthenticationRequest()
    }

    // Once per attempt, even if both the property and the signal report it
    function _fail() {
        if (root.wrong) return
        root.wrong = true
        root.wrongPassword()
    }

    PolkitAgent {
        id: agent

        // A request arrived: the polkit island takes over. It ended: back to rest.
        onIsActiveChanged: {
            root.wrong = false
            if (isActive) IslandState.openPolkit()
            else if (IslandState.polkit) IslandState.collapse()
        }
    }

    // Copy what the prompt shows; RestoreNone keeps the last value after the flow ends
    Binding {
        target: root; property: "message"
        value: agent.flow ? agent.flow.message : ""
        when: agent.flow != null
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root; property: "actionId"
        value: agent.flow ? agent.flow.actionId : ""
        when: agent.flow != null
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root; property: "userName"
        value: agent.flow && agent.flow.selectedIdentity ? (agent.flow.selectedIdentity.displayName || "") : ""
        when: agent.flow != null
        restoreMode: Binding.RestoreNone
    }

    Connections {
        target: agent.flow
        ignoreUnknownSignals: true

        function onFailedChanged() { if (agent.flow && agent.flow.failed) root._fail() }
        function onAuthenticationFailed() { root._fail() }
        // Done, or cancelled by the system: close the island
        function onIsCompletedChanged() {
            if (agent.flow && agent.flow.isCompleted && IslandState.polkit) IslandState.collapse()
        }
    }

    // Leaving the polkit island by any route (ESC, click outside, another island) cancels
    Connections {
        target: IslandState
        function onModeChanged() { if (!IslandState.polkit) root.cancel() }
    }
}