import QtQuick
import qs.Common
import qs.Widgets
import "." as Local

Rectangle {
    id: root

    property var peer: ({})

    width: parent ? parent.width : 0
    height: 32
    radius: Theme.cornerRadius / 2
    color: hover.containsMouse ? Theme.surfaceContainerHigh : "transparent"

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingS

        Local.StatusDot {
            anchors.verticalCenter: parent.verticalCenter
            state: peer.online === false ? "disconnected" : "connected"
            dotSize: 6
            animated: false
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: peer.alias || ""
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText
            width: 110
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: peer.isRelay === true
            width: relayLabel.implicitWidth + 8
            height: 14
            radius: 7
            color: Qt.rgba(0.85, 0.78, 0.48, 0.18)
            StyledText {
                id: relayLabel
                anchors.centerIn: parent
                text: "RELAY"
                font.pixelSize: 8
                font.weight: Font.Bold
                color: "#E8C57A"
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: peer.ip || ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            font.family: "JetBrains Mono, monospace"
            width: 130
            elide: Text.ElideRight
        }

        Item {
            width: Math.max(0, parent.width - 110 - 130 - Theme.spacingS * 4 - 60 - (peer.isRelay ? 50 : 0))
            height: 1
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: peer.rtt >= 0 ? peer.rtt + " ms" : "—"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            font.family: "JetBrains Mono, monospace"
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
}
