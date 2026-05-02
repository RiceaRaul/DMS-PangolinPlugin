pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // States: empty | disconnected | connecting | connected | error
    property string state: "empty"
    property bool loggedIn: false
    property string org: ""
    property var orgList: []
    property var peers: []
    property var aliases: []
    property string endpoint: ""
    property string version: ""
    property string agent: ""
    property bool registered: false
    property var ipv4Addresses: []
    property var dnsServers: []
    property var routes: []
    property int mtu: 0
    property var connectedSince: null
    property string lastError: ""
    property int lastUpdateMs: 0
    property bool cliMissing: false
    property bool hasNopasswd: false

    // Config (set by Widget from pluginData)
    property int popoutPollSec: 3
    property int backgroundPollSec: 30
    property bool liveRTT: false
    property bool popoutOpen: false
    property string terminalCommand: ""

    // Internal
    property bool _userInitiated: false
    property bool _actionInFlight: false
    property string _stderrBuf: ""
    property string _stdoutBuf: ""
    property string _aliasBuf: ""
    property string _orgBuf: ""

    function _noop(x) {}

    function _setState(s) {
        if (root.state === s)
            return;
        root.state = s;
    }

    Component.onCompleted: {
        cliProbe.running = true;
    }

    // --- Public actions ---

    function refresh() {
        if (statusProc.running)
            return;
        if (_actionInFlight)
            return;
        _stdoutBuf = "";
        _stderrBuf = "";
        statusProc.running = true;
    }

    function up() {
        if (cliMissing || _actionInFlight)
            return;
        _userInitiated = true;
        _actionInFlight = true;
        _setState("connecting");
        connectingWatchdog.restart();
        upProc.running = true;
    }

    function down() {
        if (cliMissing || _actionInFlight)
            return;
        _userInitiated = true;
        _actionInFlight = true;
        _setState("disconnecting");
        downProc.running = true;
    }

    function logout() {
        logoutProc.running = true;
    }

    function selectOrg(id) {
        selectOrgProc.command = ["pangolin", "select", "org", id];
        selectOrgProc.running = true;
    }

    function listAliases() {
        if (aliasProc.running)
            return;
        _aliasBuf = "";
        aliasProc.running = true;
    }

    function probeAuth() {
        if (orgProbe.running)
            return;
        _orgBuf = "";
        orgProbe.running = true;
    }

    function openLoginTerm() {
        terminalProc.command = _resolveTerminalCmd();
        terminalProc.running = true;
    }

    function _resolveTerminalCmd() {
        var loginCmd = "pangolin login";
        if (root.terminalCommand && root.terminalCommand.length > 0) {
            return ["sh", "-c", root.terminalCommand + " " + loginCmd];
        }
        // Try $TERMINAL then fallback chain
        var script = "for t in \"$TERMINAL\" kitty alacritty foot wezterm gnome-terminal konsole xterm; do " + "if [ -n \"$t\" ] && command -v \"$t\" >/dev/null 2>&1; then exec \"$t\" -e " + loginCmd + "; fi; done; exit 1";
        return ["sh", "-c", script];
    }

    function stateLabel() {
        switch (root.state) {
        case "connected":
            return "Connected";
        case "connecting":
            return "Connecting";
        case "disconnecting":
            return "Disconnecting";
        case "disconnected":
            return "Off";
        case "error":
            return "Error";
        default:
            return "No account";
        }
    }

    // --- Polling ---

    Timer {
        id: pollTimer
        interval: ((root.popoutOpen || root.liveRTT) ? root.popoutPollSec : root.backgroundPollSec) * 1000
        repeat: true
        running: !root.cliMissing
        triggeredOnStart: true
        onIntervalChanged: if (running) restart()
        onTriggered: root.refresh()
    }

    onPopoutOpenChanged: if (popoutOpen) refresh()
    onLiveRTTChanged: if (liveRTT) refresh()

    Timer {
        id: authTimer
        interval: 60000
        repeat: true
        running: !root.cliMissing
        triggeredOnStart: true
        onTriggered: root.probeAuth()
    }

    Timer {
        id: connectingWatchdog
        interval: 30000
        repeat: false
        onTriggered: {
            if (root.state === "connecting") {
                root.lastError = "Connection timed out";
                root._setState("error");
                _noop(root.lastError);
            }
        }
    }

    Timer {
        id: statusKill
        interval: 5000
        repeat: false
        onTriggered: {
            if (statusProc.running) {
                statusProc.signal(15);
            }
        }
    }

    // --- Processes ---

    Process {
        id: cliProbe
        command: ["sh", "-c", "command -v pangolin >/dev/null 2>&1"]
        onExited: (code, status) => {
            root.cliMissing = (code !== 0);
            if (root.cliMissing) {
                root.lastError = "Pangolin CLI not installed";
                root._setState("error");
            } else {
                authDaemonProc.running = true;
            }
        }
    }

    Process {
        id: authDaemonProc
        command: ["sh", "-c", "pgrep -f 'pangolin auth-daemon' >/dev/null || setsid pangolin auth-daemon </dev/null >/dev/null 2>&1 &"]
        running: false
        onExited: (code, status) => {
            // Give daemon ~500ms to bind socket
            daemonStartTimer.restart();
        }
    }

    Timer {
        id: daemonStartTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.refresh();
            root.probeAuth();
            root.listAliases();
        }
    }

    Process {
        id: statusProc
        command: ["pangolin", "status", "--json"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._stdoutBuf += data
        }
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => root._stderrBuf += data
        }
        onStarted: statusKill.restart()
        onExited: (code, status) => {
            statusKill.stop();
            root._applyStatus(code, root._stdoutBuf, root._stderrBuf);
            root.lastUpdateMs = Date.now();
        }
    }

    readonly property string _pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "").replace(/\/services\/?$/, "")
    readonly property string _askpassPath: root._pluginDir + "/askpass.sh"

    function _sudoCmd(args) {
        if (root.hasNopasswd)
            return "sudo -n " + args;
        return "SUDO_ASKPASS='" + root._askpassPath + "' sudo -A -E " + args;
    }

    function installSudoers() {
        installSudoersProc.command = ["sh", "-c", "SUDO_ASKPASS='" + root._askpassPath + "' SUDO_USER=$(whoami) sudo -A -E sh '" + root._pluginDir + "/install-sudoers.sh'"];
        installSudoersProc.running = true;
    }

    function uninstallSudoers() {
        uninstallSudoersProc.command = ["sh", "-c", root._sudoCmd("sh '" + root._pluginDir + "/uninstall-sudoers.sh'")];
        uninstallSudoersProc.running = true;
    }

    Timer {
        id: nopasswdProbeTimer
        interval: 5000
        repeat: true
        running: !root.cliMissing
        triggeredOnStart: true
        onTriggered: nopasswdProbe.running = true
    }

    Process {
        id: nopasswdProbe
        command: ["sh", "-c", "sudo -n pangolin status >/dev/null 2>&1"]
        running: false
        onExited: (code, status) => {
            root.hasNopasswd = (code === 0);
        }
    }

    Process {
        id: installSudoersProc
        running: false
        onExited: (code, status) => {
            nopasswdProbe.running = true;
        }
    }

    Process {
        id: uninstallSudoersProc
        running: false
        onExited: (code, status) => {
            root.hasNopasswd = false;
        }
    }

    Process {
        id: upProc
        command: ["sh", "-c", root._sudoCmd("pangolin up --silent")]
        running: false
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => root._stderrBuf += data
        }
        onStarted: root._stderrBuf = ""
        onExited: (code, status) => {
            if (code !== 0) {
                root.lastError = (root._stderrBuf || "Failed to start client").trim();
                root._setState("error");
                root._actionInFlight = false;
                root.refresh();
                return;
            }
            // Hold action gate for grace window so stale status polls don't flip back.
            graceTimer.restart();
        }
    }

    Process {
        id: downProc
        command: ["sh", "-c", root._sudoCmd("pangolin down")]
        running: false
        onExited: (code, status) => {
            root.peers = [];
            root._setState("disconnected");
            graceTimer.restart();
        }
    }

    Timer {
        id: graceTimer
        interval: 2500
        repeat: false
        onTriggered: {
            root._actionInFlight = false;
            root._userInitiated = false;
            root.refresh();
        }
    }

    Process {
        id: logoutProc
        command: ["pangolin", "logout"]
        running: false
        onExited: (code, status) => {
            root.loggedIn = false;
            root.org = "";
            root._setState("empty");
                    }
    }

    Process {
        id: selectOrgProc
        running: false
        onExited: (code, status) => {
            if (code === 0)
                root.probeAuth();
        }
    }

    Process {
        id: orgProbe
        command: ["pangolin", "auth", "status"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._orgBuf += data
        }
        onExited: (code, status) => {
            root._applyAuth(code, root._orgBuf);
        }
    }

    Process {
        id: aliasProc
        command: ["pangolin", "list", "aliases"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._aliasBuf += data
        }
        onExited: (code, status) => {
            if (code === 0) {
                var lines = root._aliasBuf.split("\n").map(s => s.trim()).filter(s => s.length > 0);
                root.aliases = lines;
            }
        }
    }

    Process {
        id: terminalProc
        running: false
    }

    // --- Parsers ---

    function _applyStatus(code, stdout, stderr) {
        if (root._actionInFlight)
            return;
        if (code !== 0) {
            // CLI failure path. "No client" can also exit 0 with stderr-style msg.
            var combined = (stderr + stdout).toLowerCase();
            if (combined.indexOf("not logged in") >= 0 || combined.indexOf("login required") >= 0) {
                root.loggedIn = false;
                root._setState("empty");
                return;
            }
            root.lastError = (stderr || stdout || "pangolin status failed").trim();
            root._setState("error");
            _noop(root.lastError);
            return;
        }

        var trimmed = stdout.trim();

        // Common literal response when nothing running
        if (trimmed.toLowerCase().indexOf("no client is currently running") >= 0) {
            root.peers = [];
            if (!root.loggedIn) {
                root._setState("empty");
            } else if (root.state !== "connecting") {
                root._setState("disconnected");
            }
            return;
        }

        // Try JSON parse
        var data = null;
        try {
            data = JSON.parse(trimmed);
        } catch (e) {
            // fall through; treat as disconnected if empty
            if (trimmed.length === 0) {
                root._setState(root.loggedIn ? "disconnected" : "empty");
                return;
            }
            root.lastError = "Failed to parse status output";
            root._setState("error");
            return;
        }

        var running = data.running === true || data.connected === true || data.status === "connected" || data.status === "running" || (data.client && data.client.running === true);

        if (!running) {
            root.peers = [];
            root._setState(root.loggedIn ? "disconnected" : "empty");
            return;
        }

        // Extract org
        root.org = data.orgId || data.org || data.organization || "";

        // Version / agent / registered
        root.version = data.version || "";
        root.agent = data.agent || "";
        root.registered = data.registered === true;

        // Network settings
        var ns = data.networkSettings || {};
        root.ipv4Addresses = ns.ipv4_addresses || [];
        root.dnsServers = ns.dns_servers || [];
        root.mtu = ns.mtu || 0;
        var rs = [];
        var ir = ns.ipv4_included_routes || [];
        for (var ri = 0; ri < ir.length; ri++) {
            rs.push((ir[ri].destination_address || "") + " / " + (ir[ri].subnet_mask || ""));
        }
        root.routes = rs;

        // Extract since
        if (data.since)
            root.connectedSince = new Date(data.since);
        else if (data.connectedAt)
            root.connectedSince = new Date(data.connectedAt);
        else if (root.state !== "connected")
            root.connectedSince = new Date();

        // Extract peers
        var peerList = [];
        var raw = data.peers || data.clients || [];
        if (Array.isArray(raw)) {
            for (var i = 0; i < raw.length; i++) {
                var p = raw[i];
                peerList.push({
                    id: p.id || p.peerId || p.siteId || String(i),
                    alias: p.alias || p.name || p.hostname || ("peer-" + i),
                    ip: p.endpoint || p.ip || p.address || "",
                    rtt: (typeof p.rtt === "number") ? p.rtt : (typeof p.latency === "number") ? p.latency : -1,
                    lastSeen: p.lastSeen || "",
                    isRelay: p.isRelay === true,
                    online: p.connected !== false && p.online !== false
                });
            }
        } else if (typeof raw === "object" && raw !== null) {
            for (var k in raw) {
                var pp = raw[k];
                peerList.push({
                    id: pp.siteId || k,
                    alias: pp.name || pp.alias || pp.hostname || k,
                    ip: pp.endpoint || pp.ip || pp.address || "",
                    rtt: (typeof pp.rtt === "number") ? pp.rtt : -1,
                    lastSeen: pp.lastSeen || "",
                    isRelay: pp.isRelay === true,
                    online: pp.connected !== false && pp.online !== false
                });
            }
        }
        root.peers = peerList;
        root.endpoint = (peerList.length > 0 && peerList[0].ip) ? peerList[0].ip : (root.ipv4Addresses[0] || "");
        
        if (root.state !== "connected") {
            connectingWatchdog.stop();
            root._setState("connected");
        }
    }

    function _applyAuth(code, stdout) {
        if (code !== 0) {
            root.loggedIn = false;
            root.org = "";
            root.orgList = [];
            if (root.state !== "error")
                root._setState("empty");
                        return;
        }
        var lines = stdout.split("\n").map(s => s.trim()).filter(s => s.length > 0);
        root.orgList = lines;
        if (!root.loggedIn) {
            root.loggedIn = true;
                        // Trigger fresh status to leave 'empty'
            root.refresh();
        } else {
            root.loggedIn = true;
        }
    }
}
