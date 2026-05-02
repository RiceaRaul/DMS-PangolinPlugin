pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool muteAll: false
    property bool notifyOnError: true
    property bool notifyOnConnect: false
    property bool notifyOnDisconnect: true
    property bool notifyOnUserActions: false

    function configure(opts) {
        if (opts.muteAll !== undefined)
            root.muteAll = opts.muteAll;
        if (opts.notifyOnError !== undefined)
            root.notifyOnError = opts.notifyOnError;
        if (opts.notifyOnConnect !== undefined)
            root.notifyOnConnect = opts.notifyOnConnect;
        if (opts.notifyOnDisconnect !== undefined)
            root.notifyOnDisconnect = opts.notifyOnDisconnect;
        if (opts.notifyOnUserActions !== undefined)
            root.notifyOnUserActions = opts.notifyOnUserActions;
    }

    function send(title, body, urgency) {
        notifyProc.command = ["notify-send", "-a", "Pangolin", "-i", "vpn_lock", "-u", urgency || "normal", title, body];
        notifyProc.running = true;
    }

    Connections {
        target: PangolinService
        function onStateChanged() {
            console.log("[PangolinNotifier] state=" + PangolinService.state + " mute=" + root.muteAll + " err=" + root.notifyOnError + " conn=" + root.notifyOnConnect + " disc=" + root.notifyOnDisconnect + " user=" + root.notifyOnUserActions + " uInit=" + PangolinService._userInitiated);
            if (root.muteAll === true)
                return;
            var s = PangolinService.state;
            var userAction = PangolinService._userInitiated;
            if (userAction && !root.notifyOnUserActions && s !== "error")
                return;
            if (s === "connected" && root.notifyOnConnect) {
                root.send("Pangolin", "Tunnel connected", "low");
            } else if (s === "error" && root.notifyOnError) {
                root.send("Pangolin error", PangolinService.lastError || "Unknown error", "normal");
            } else if (s === "disconnected" && root.notifyOnDisconnect) {
                root.send("Pangolin", "Tunnel disconnected", "normal");
            }
        }
    }

    Process {
        id: notifyProc
        running: false
    }
}
