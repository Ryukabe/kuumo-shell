import QtQuick
import "../styles"
import "../state"

// A digital clock. When the time changes only the digits that change move: the new digit rises
// into its window while the old one leaves through the top. The separators (":") stay put and
// pulse gently once a second. Every digit has the same width, so nothing shifts. It takes the
// place of NumberFlow: the same text, pixelSize, weight and animated, and it scales and moves like
// any item. With reduced motion the digits change at once and the separators hold still.
Item {
    id: root

    // The time as text, for example "23:58"
    property string text: ""
    property int pixelSize: Theme.fontSizeMd
    property int weight: Font.Normal
    property color color: Theme.fg
    // The separators pulse
    property bool blink: true
    property bool animated: true

    property font font
    font.family: Theme.fontText
    font.pixelSize: root.pixelSize
    font.weight: root.weight

    readonly property bool rolling: root.animated && !ShellState.motionReduced

    TextMetrics {
        id: metrics
        font: root.font
        text: "0"
    }
    readonly property real digitW: metrics.advanceWidth
    readonly property real lineH: metrics.height

    implicitWidth: row.implicitWidth
    implicitHeight: root.lineH

    Row {
        id: row

        Repeater {
            model: root.text.length

            Item {
                id: slot
                required property int index

                readonly property string ch: root.text.charAt(index)
                readonly property bool digit: ch >= "0" && ch <= "9"
                // The digit in the window now, the one leaving, and how far the change has gone (0..1)
                property string shownCh: ch
                property string leavingCh: ""
                property real rise: 1
                // The separator's pulse (1 = full strength)
                property real pulse: 1

                width: slot.digit ? root.digitW : separator.implicitWidth
                height: root.lineH
                clip: true

                // A separator stays put and pulses
                Text {
                    id: separator
                    visible: !slot.digit
                    anchors.verticalCenter: parent.verticalCenter
                    text: slot.ch
                    color: root.color
                    font: root.font
                    opacity: root.blink && root.rolling ? slot.pulse : 1
                }

                // A digit: the old one leaves through the top while the new one rises in
                Text {
                    visible: slot.digit && slot.rise < 1
                    width: slot.width
                    horizontalAlignment: Text.AlignHCenter
                    y: -slot.rise * slot.height
                    text: slot.leavingCh
                    color: root.color
                    font: root.font
                }

                Text {
                    visible: slot.digit
                    width: slot.width
                    horizontalAlignment: Text.AlignHCenter
                    y: (1 - slot.rise) * slot.height
                    text: slot.shownCh
                    color: root.color
                    font: root.font
                }

                onChChanged: {
                    if (slot.digit && root.rolling && /[0-9]/.test(slot.shownCh) && slot.shownCh !== slot.ch) {
                        slot.leavingCh = slot.shownCh
                        slot.shownCh = slot.ch
                        slot.rise = 0
                        roll.restart()
                    } else {
                        slot.shownCh = slot.ch
                        slot.rise = 1
                    }
                }

                NumberAnimation {
                    id: roll
                    target: slot
                    property: "rise"
                    from: 0
                    to: 1
                    duration: Motion.clockDigitMs
                    easing.type: Easing.OutCubic
                }

                SequentialAnimation on pulse {
                    running: root.blink && !slot.digit && root.rolling
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: Motion.clockPulseDim
                        duration: Motion.clockPulseMs / 2
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1
                        duration: Motion.clockPulseMs / 2
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}