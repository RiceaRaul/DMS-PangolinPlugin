import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./components" as PW
import "./services" as Services

PluginComponent {
    id: root

    property string barMode: pluginData.barMode || "icon_state"
    property string orgLabel: Services.PangolinService.org

    Component.onCompleted: applySettings()
    onPluginDataChanged: applySettings()

    function applySettings() {
        Services.PangolinService.popoutPollSec = pluginData.popoutPollSec || 3;
        Services.PangolinService.backgroundPollSec = pluginData.backgroundPollSec || 30;
        Services.PangolinService.liveRTT = pluginData.liveRTT === true;
        Services.PangolinService.terminalCommand = pluginData.terminalCommand || "";

        Services.PangolinNotifier.muteAll = pluginData.muteAll === true;
        Services.PangolinNotifier.notifyOnError = pluginData.notifyOnError !== false;
        Services.PangolinNotifier.notifyOnConnect = pluginData.notifyOnConnect === true;
        Services.PangolinNotifier.notifyOnDisconnect = pluginData.notifyOnDisconnect !== false;
        Services.PangolinNotifier.notifyOnUserActions = pluginData.notifyOnUserActions === true;
        console.log("[PangolinWidget] applySettings: muteAll=" + (pluginData.muteAll === true) + " connect=" + (pluginData.notifyOnConnect === true));
    }

    horizontalBarPill: Component {
        PW.HorizontalPill {
            barMode: root.barMode
        }
    }

    verticalBarPill: Component {
        PW.VerticalPill {
            barMode: root.barMode
        }
    }

    popoutContent: Component {
        PW.PopoutBody {
            maxPopoutHeight: root.popoutHeight
        }
    }

    controlCenterWidget: Component {
        PW.QuickTile {
            orgLabel: root.orgLabel
        }
    }

    ccDetailContent: Component {
        PW.PopoutBody {
            popoutWidth: 360
            maxPopoutHeight: root.ccDetailHeight
        }
    }

    ccWidgetIcon: "vpn_lock"
    ccWidgetPrimaryText: "Pangolin"
    ccWidgetSecondaryText: Services.PangolinService.stateLabel()
    ccWidgetIsActive: Services.PangolinService.state === "connected"
    ccWidgetIsToggle: true
    ccDetailHeight: {
        switch (Services.PangolinService.state) {
        case "connected":
            return Math.min(640, 380 + Services.PangolinService.peers.length * 36);
        case "empty":
            return 360;
        default:
            return 340;
        }
    }

    onCcWidgetToggled: {
        if (Services.PangolinService.state === "connected") {
            Services.PangolinService.down();
        } else if (Services.PangolinService.state === "disconnected" || Services.PangolinService.state === "error") {
            Services.PangolinService.up();
        } else if (Services.PangolinService.state === "empty") {
            Services.PangolinService.openLoginTerm();
        }
    }

    popoutWidth: 400
    popoutHeight: {
        switch (Services.PangolinService.state) {
        case "connected":
            return Math.min(780, 380 + Services.PangolinService.peers.length * 36);
        case "connecting":
            return 320;
        case "empty":
            return 380;
        case "error":
            return 360;
        default:
            return 360;
        }
    }
}
