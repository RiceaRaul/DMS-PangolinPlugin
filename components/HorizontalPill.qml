import QtQuick
import qs.Common
import qs.Widgets
import "." as Local
import "../services" as Services

Row {
    id: root
    spacing: Theme.spacingS

    property string barMode: "icon_state"

    DankIcon {
        name: "vpn_lock"
        size: Theme.iconSize
        color: Services.PangolinService.state === "connected" ? Theme.primary : Theme.surfaceVariantText
        anchors.verticalCenter: parent.verticalCenter
    }

    Local.StatusDot {
        state: Services.PangolinService.state
        dotSize: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: root.barMode !== "icon_only"
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceText
        visible: text.length > 0 && root.barMode !== "icon_only"
        text: {
            if (root.barMode === "icon_org" && Services.PangolinService.org)
                return Services.PangolinService.org;
            if (root.barMode === "icon_peers")
                return Services.PangolinService.state === "connected" ? Services.PangolinService.peers.length + " peers" : "";
            return Services.PangolinService.stateLabel();
        }
    }
}
