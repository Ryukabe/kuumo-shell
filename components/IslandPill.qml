import QtQuick
import "../styles"

// Base island shape. Size is set from outside; the radius follows the height.
Rectangle {
    property real maxRadius: 28

    radius: Math.min(height / 2, maxRadius)
    color: Theme.subBg
    border.width: 1
    border.color: Theme.border
    clip: true
}