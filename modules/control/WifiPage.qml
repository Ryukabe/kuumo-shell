pragma ComponentBehavior: Bound

import QtQuick
import "../../styles"
import "../network"

// The Wi-Fi list page of the control center: a back arrow on top, then the networks around.
// Tap a network to open its actions (connect, disconnect, forget, or type a password).
Item {
    id: root

    // The control layout block from Island.qml
    required property var layout

    // The back arrow was tapped
    signal back()

    // The network whose actions are open; "" means none
    property string expandedSsid: ""

    // ── The networks, kept in a model so rows update in place instead of being rebuilt ──
    ListModel { id: networkModel }

    // Copies the service's list into the model. When only the details changed (signal,
    // saved, connected) the rows are updated in place; when networks came or went the
    // model is refilled.
    function syncModel(rows) {
        const sameNetworks = rows.length === networkModel.count
            && rows.every((row, i) => networkModel.get(i).ssid === row.ssid)

        if (sameNetworks) {
            for (let i = 0; i < rows.length; i++) networkModel.set(i, rows[i])
        } else {
            networkModel.clear()
            for (const row of rows) networkModel.append(row)
        }
    }

    Connections {
        target: WifiService
        function onNetworksChanged() { root.syncModel(WifiService.networks) }
    }

    Component.onCompleted: syncModel(WifiService.networks)

    // ── Header: back arrow, title, and a note while scanning ──
    PageHeader {
        id: header
        layout: root.layout
        width: parent.width
        title: "Wi-Fi"
        note: "Scanning…"
        noteShown: WifiService.scanning && WifiService.radioOn
        onBack: root.back()
    }

    // ── The networks ──
    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: root.layout.rowGap
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: root.layout.netRowGap
        boundsBehavior: Flickable.StopAtBounds
        model: networkModel

        delegate: NetworkRow {
            // The roles from the model (ssid, level, secured, known, active) fill the
            // required properties of NetworkRow by name
            layout: root.layout
            width: list.width
            expanded: root.expandedSsid === ssid

            onToggle: root.expandedSsid = expanded ? "" : ssid
            onConnectRequested: password => {
                WifiService.connectTo(ssid, password)
                root.expandedSsid = ""
            }
            onDisconnectRequested: {
                WifiService.disconnect()
                root.expandedSsid = ""
            }
            onForgetRequested: {
                WifiService.forget(ssid)
                root.expandedSsid = ""
            }
        }
    }

    // Shown instead of the list when there is nothing to list
    Text {
        anchors.centerIn: list
        visible: networkModel.count === 0
        text: !WifiService.radioOn ? "Wi-Fi is off"
            : WifiService.scanning ? "Looking for networks…"
            : "No networks found"
        color: Theme.fgMuted
        font.family: Theme.fontText
        font.pixelSize: Theme.fontSizeSm
    }
}