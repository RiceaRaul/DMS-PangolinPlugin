import QtQuick
import qs.Common
import qs.Widgets
import "." as Local
import "../services" as Services

Rectangle {
    id: root

    property string orgLabel: ""

    width: 260
    height: 120
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Theme.outline

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        Row {
            spacing: Theme.spacingS
            width: parent.width

            Local.StatusDot {
                anchors.verticalCenter: parent.verticalCenter
                state: Services.PangolinService.state
                dotSize: 10
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 10 - 36 - Theme.spacingS * 2
                spacing: 2

                StyledText {
                    text: "Pangolin"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }

                StyledText {
                    text: Services.PangolinService.stateLabel() + (root.orgLabel ? " · " + root.orgLabel : "")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 20
                radius: 10
                color: Services.PangolinService.state === "connected" ? Theme.primary : Theme.surfaceVariantText
                opacity: Services.PangolinService.state === "connecting" ? 0.5 : 1
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: "white"
                    y: 2
                    x: Services.PangolinService.state === "connected" ? parent.width - width - 2 : 2
                    Behavior on x {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.3
        }

        Row {
            spacing: Theme.spacingL
            width: parent.width

            Column {
                spacing: 2
                StyledText {
                    text: "PEERS"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }
                StyledText {
                    text: Services.PangolinService.state === "connected" ? Services.PangolinService.peers.length.toString() : "—"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    font.family: "JetBrains Mono, monospace"
                }
            }

            Column {
                spacing: 2
                StyledText {
                    text: "AVG RTT"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }
                StyledText {
                    text: {
                        if (Services.PangolinService.state !== "connected")
                            return "—";
                        var ps = Services.PangolinService.peers;
                        var sum = 0, n = 0;
                        for (var i = 0; i < ps.length; i++) {
                            if (ps[i].rtt >= 0) {
                                sum += ps[i].rtt;
                                n++;
                            }
                        }
                        return n > 0 ? Math.round(sum / n) + " ms" : "—";
                    }
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    font.family: "JetBrains Mono, monospace"
                }
            }

            Column {
                spacing: 2
                StyledText {
                    text: "ROUTES"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }
                StyledText {
                    text: Services.PangolinService.aliases.length.toString()
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    font.family: "JetBrains Mono, monospace"
                }
            }
        }
    }
}
