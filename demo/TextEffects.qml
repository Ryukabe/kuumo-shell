import QtQuick
import Quickshell
import "../components"
import "../styles"

// A test window for the text effects, run next to the shell:
//   qs -p ~/.config/quickshell/demo/TextEffects.qml
// Close the window (or press Ctrl+C in the terminal) to stop it.
ShellRoot {
    FloatingWindow {
        implicitWidth: 560
        implicitHeight: 600
        color: Theme.bg

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            component Caption: Text {
                color: Theme.fgMuted
                font.family: Theme.fontText
                font.pixelSize: Theme.fontSizeXs
            }

            Caption { text: "TypingText: two lines, typed, kept, deleted, next" }
            TypingText {
                lines: ["Search themes...", "Search wallpapers..."]
                font.pixelSize: 18
            }

            Caption { text: "BackspaceText: deletes only back to what the lines share" }
            BackspaceText {
                id: backspace
                font.pixelSize: 18
                property var phrases: ["Build a website.", "Build an app.", "Build a business."]
                property int which: 0
                text: phrases[which]
            }
            Timer {
                interval: 4200
                running: true
                repeat: true
                onTriggered: backspace.which = (backspace.which + 1) % backspace.phrases.length
            }

            Caption { text: "IrisText: click it to play again" }
            IrisText {
                id: iris
                text: "Everblush"
                font.pixelSize: 28
                font.bold: true
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        iris.text = ""
                        iris.text = "Everblush"
                    }
                }
            }

            Caption { text: "ClockText: a minute passes every 1.5 s" }
            ClockText {
                id: clock
                pixelSize: 36
                weight: Font.Bold
                property int minutes: 23 * 60 + 58
                function pad(n) { return n < 10 ? "0" + n : String(n) }
                text: pad(Math.floor(minutes / 60) % 24) + ":" + pad(minutes % 60)
            }
            Timer {
                interval: 1500
                running: true
                repeat: true
                onTriggered: clock.minutes += 1
            }

            Caption { text: "PasswordText: press the eye" }
            PasswordText {
                text: "correct horse"
                font.pixelSize: 18
            }

            Caption { text: "CopyText: press it (copies with wl-copy)" }
            CopyText {
                id: copy
                width: 320
                height: 28
                onCopyRequested: {
                    Quickshell.execDetached(["wl-copy", "qs ipc call island theme"])
                    copy.markCopied()
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "qs ipc call island theme"
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeMd
                }
            }
        }
    }
}