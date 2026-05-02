import QtQuick
import qs.Common
import qs.Widgets
import "../services" as Services

Column {
    id: root
    spacing: Theme.spacingM
    width: parent ? parent.width : 0

    DankIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        name: "lock"
        size: 36
        color: Theme.surfaceVariantText
    }

    StyledText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Not logged in"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Run pangolin login in a terminal to authenticate."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 160
        height: 36
        radius: Theme.cornerRadius
        color: loginArea.containsMouse ? Theme.primaryHover : Theme.primary

        StyledText {
            anchors.centerIn: parent
            text: "Open Login"
            color: Theme.onPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
        }

        MouseArea {
            id: loginArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Services.PangolinService.openLoginTerm()
        }
    }
}
