pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../styles"

Singleton {
    id: root

    // The most recently seen player. Set when a player appears or starts playing.
    property MprisPlayer recent: null

    readonly property var players: Mpris.players.values

    // A playing player wins (the most recent one if several play).
    // Otherwise the most recent player, or the last one in the list.
    readonly property MprisPlayer active: {
        const list = root.players
        if (root.recent && list.includes(root.recent) && root.recent.isPlaying)
            return root.recent
        for (const p of list) {
            if (p.isPlaying) return p
        }
        if (root.recent && list.includes(root.recent)) return root.recent
        return list.length > 0 ? list[list.length - 1] : null
    }

    readonly property bool hasPlayer: active !== null
    readonly property bool isPlaying: active ? active.isPlaying : false
    readonly property string title: active ? (active.trackTitle || active.identity) : "Nothing playing"
    readonly property string artist: active ? active.trackArtist : ""
    readonly property string artUrl: active ? active.trackArtUrl : ""

    // Which way the last skip went: 1 for next (also when a track ends by itself),
    // -1 for previous. Set when a skip is requested, so it is already right when
    // the new track's title arrives.
    property int pendingDirection: 1

    // Emitted when the same player moves to another track
    signal trackChanged(int direction)

    function togglePlaying() { if (active && active.canTogglePlaying) active.togglePlaying() }

    function next() {
        if (active && active.canGoNext) {
            pendingDirection = 1
            skipWindow.restart()
            active.next()
        }
    }

    function previous() {
        if (active && active.canGoPrevious) {
            pendingDirection = -1
            skipWindow.restart()
            active.previous()
        }
    }

    // A skip that changes nothing (first track, end of list) must not colour a later change
    Timer {
        id: skipWindow
        interval: Motion.skipWindow
        onTriggered: root.pendingDirection = 1
    }

    Connections {
        target: root.active
        function onTrackTitleChanged() { root.trackChanged(root.pendingDirection) }
    }

    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            required property MprisPlayer modelData
            readonly property bool playing: modelData.isPlaying
            onPlayingChanged: if (playing) root.recent = modelData
            Component.onCompleted: root.recent = modelData
        }
    }
}