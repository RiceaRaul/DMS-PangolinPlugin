import QtQuick
import qs.Common
import qs.Widgets
import "." as Local
import "../services" as Services

Column {
    id: root
    spacing: Theme.spacingXS

    property string barMode: "icon_state"

    DankIcon {
        name: "vpn_lock"
        size: Theme.iconSize
        color: Services.PangolinService.state === "connected" ? Theme.primary : Theme.surfaceVariantText
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Local.StatusDot {
        state: Services.PangolinService.state
        dotSize: 8
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.barMode !== "icon_only"
    }
}
