import QtQuick
import "../../components"
import "../../styles"

Item {
    readonly property bool hasWorkspaces: WorkspacesService.ids.length > 0

    implicitWidth: hasWorkspaces ? row.implicitWidth : fallback.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row
        visible: hasWorkspaces
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: WorkspacesService.ids

            PillButton {
                required property var modelData
                required property int index

                label: String(modelData)
                checked: (index + 1) === WorkspacesService.active
            }
        }
    }

    Text {
        id: fallback
        visible: !hasWorkspaces
        anchors.verticalCenter: parent.verticalCenter
        text: "Spaces"
        color: Theme.colors.muted
        font.pixelSize: 12
        font.family: Theme.fontFamily
    }
}
