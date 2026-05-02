import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services
import "." as Local
import "../services" as Services

PopoutComponent {
    id: root

    headerText: ""
    detailsText: ""
    showCloseButton: false

    property int popoutWidth: 400
    property int maxPopoutHeight: 600
    property bool routesExpanded: true
    property real nowMs: Date.now()

    Component.onCompleted: {
        Services.PangolinService.popoutOpen = true;
        Services.PangolinService.refresh();
    }
    Component.onDestruction: {
        Services.PangolinService.popoutOpen = false;
    }

    function _fmtSince(d) {
        if (!d)
            return "";
        var _ = root.nowMs;
        var diff = Math.max(0, Math.floor((Date.now() - d.getTime()) / 1000));
        if (diff < 60)
            return diff + "s";
        if (diff < 3600)
            return Math.floor(diff / 60) + "m";
        return Math.floor(diff / 3600) + "h";
    }

    function _fmtAgo(iso) {
        if (!iso)
            return "—";
        var _ = root.nowMs;
        var t = Date.parse(iso);
        if (isNaN(t))
            return "—";
        var diff = Math.max(0, Math.floor((Date.now() - t) / 1000));
        if (diff < 5)
            return "just now";
        if (diff < 60)
            return diff + "s ago";
        if (diff < 3600)
            return Math.floor(diff / 60) + "m ago";
        return Math.floor(diff / 3600) + "h ago";
    }

    function _stateTitle() {
        switch (Services.PangolinService.state) {
        case "connected":
            return "Connected";
        case "connecting":
            return "Connecting…";
        case "disconnecting":
            return "Disconnecting…";
        case "disconnected":
            return "Disconnected";
        case "error":
            return "Error";
        default:
            return "Not signed in";
        }
    }

    function _stateSubtitle() {
        switch (Services.PangolinService.state) {
        case "connected":
            return "Tunnel active";
        case "connecting":
            return "Negotiating WireGuard handshake";
        case "disconnecting":
            return "Tearing down tunnel";
        case "disconnected":
            return "Tap toggle to connect";
        case "error":
            return Services.PangolinService.lastError || "Tunnel failed";
        default:
            return "Login required";
        }
    }

    function _stateAccent() {
        switch (Services.PangolinService.state) {
        case "connected":
            return "#9BD4A8";
        case "connecting":
        case "disconnecting":
            return "#E8C57A";
        case "error":
            return Theme.error;
        default:
            return Theme.surfaceVariantText;
        }
    }

    Item {
        id: bodyContainer
        width: parent.width
        implicitHeight: Math.max(60, Math.min(bodyCol.implicitHeight + Theme.spacingS, root.maxPopoutHeight))
        height: implicitHeight

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: false
            onPressed: mouse => mouse.accepted = true
            onClicked: mouse => mouse.accepted = true
            z: -1
        }

        DankFlickable {
            id: scroll
            anchors.fill: parent
            contentWidth: width
            contentHeight: bodyCol.implicitHeight
            clip: true

        Column {
            id: bodyCol
            width: scroll.width
            spacing: Theme.spacingM

            // ---- Header card ----
            Rectangle {
                width: parent.width
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                border.width: 1
                implicitHeight: headerRow.implicitHeight + Theme.spacingM * 2

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: Theme.surfaceContainerHighest
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
                        border.width: 1
                        DankIcon {
                            anchors.centerIn: parent
                            name: "vpn_lock"
                            size: 22
                            color: Theme.surfaceText
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Row {
                            spacing: Theme.spacingXS
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Pangolin VPN"
                                font.pixelSize: Theme.fontSizeMedium + 1
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Services.PangolinService.version.length > 0
                                width: verLabel.implicitWidth + 10
                                height: 16
                                radius: 4
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                                StyledText {
                                    id: verLabel
                                    anchors.centerIn: parent
                                    text: "v" + Services.PangolinService.version
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                    font.family: "JetBrains Mono, monospace"
                                }
                            }
                        }

                        Row {
                            spacing: 4
                            DankIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "folder"
                                size: 12
                                color: Theme.surfaceVariantText
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Services.PangolinService.org || "—"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }

            // ---- State + toggle card ----
            Rectangle {
                width: parent.width
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                border.width: 1
                implicitHeight: stateRow.implicitHeight + Theme.spacingM * 2

                RowLayout {
                    id: stateRow
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    // Animated state ring
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: "transparent"
                        border.color: root._stateAccent()
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 5
                            color: root._stateAccent()
                            opacity: Services.PangolinService.state === "connecting" ? 1 : 0.85

                            SequentialAnimation on opacity {
                                running: Services.PangolinService.state === "connecting" || Services.PangolinService.state === "disconnecting"
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: 1.0
                                    to: 0.3
                                    duration: 700
                                }
                                NumberAnimation {
                                    from: 0.3
                                    to: 1.0
                                    duration: 700
                                }
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: root._stateTitle()
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                        StyledText {
                            text: root._stateSubtitle()
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            width: parent.width
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    // Pill toggle
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 30
                        radius: 15
                        color: Services.PangolinService.state === "connected" ? Theme.primary : Theme.surfaceVariantText
                        opacity: (Services.PangolinService.state === "connecting" || Services.PangolinService.state === "disconnecting" || Services.PangolinService.state === "empty" || Services.PangolinService.cliMissing) ? 0.5 : 1

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: "white"
                            y: 4
                            x: Services.PangolinService.state === "connected" ? parent.width - width - 4 : 4
                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 160
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: Services.PangolinService.state !== "connecting" && Services.PangolinService.state !== "disconnecting" && Services.PangolinService.state !== "empty" && !Services.PangolinService.cliMissing
                            onClicked: mouse => {
                                mouse.accepted = true;
                                if (Services.PangolinService.state === "connected")
                                    Services.PangolinService.down();
                                else
                                    Services.PangolinService.up();
                            }
                        }
                    }
                }
            }

            // ---- Empty / error / cli-missing banners ----
            Local.EmptyAuth {
                width: parent.width
                visible: Services.PangolinService.state === "empty"
            }


            Rectangle {
                width: parent.width
                height: 50
                radius: Theme.cornerRadius
                color: Theme.errorHover
                visible: Services.PangolinService.cliMissing
                StyledText {
                    anchors.centerIn: parent
                    text: "Pangolin CLI not found in PATH"
                    color: Theme.error
                    font.weight: Font.Medium
                }
            }

            // ---- Section: CONNECTION ----
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: Services.PangolinService.state === "connected"

                StyledText {
                    text: "CONNECTION"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.6
                    color: Theme.surfaceVariantText
                }

                Rectangle {
                    width: parent.width
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer
                    border.color: Theme.outline
                    border.width: 1
                    implicitHeight: connCol.implicitHeight

                    Column {
                        id: connCol
                        width: parent.width
                        spacing: 0

                        Repeater {
                            model: {
                                var rows = [];
                                rows.push({
                                    icon: "lan",
                                    k: "Client IP",
                                    v: Services.PangolinService.ipv4Addresses.join(", ") || "—"
                                });
                                rows.push({
                                    icon: "dns",
                                    k: "DNS",
                                    v: Services.PangolinService.dnsServers.join(", ") || "—"
                                });
                                rows.push({
                                    icon: "swap_horiz",
                                    k: "MTU",
                                    v: Services.PangolinService.mtu > 0 ? Services.PangolinService.mtu.toString() : "—"
                                });
                                return rows;
                            }
                            delegate: Item {
                                width: connCol.width
                                height: 40

                                Rectangle {
                                    visible: index > 0
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    height: 1
                                    color: Theme.outline
                                    opacity: 0.25
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        name: modelData.icon
                                        size: 16
                                        color: Theme.surfaceVariantText
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: modelData.k
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: modelData.v
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        font.family: "JetBrains Mono, monospace"
                                        color: Theme.primary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Section: PEERS ----
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: Services.PangolinService.state === "connected" && Services.PangolinService.peers.length > 0

                Item {
                    width: parent.width
                    height: 14
                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PEERS"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                        color: Theme.surfaceVariantText
                    }
                    StyledText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Services.PangolinService.peers.length + " SITES"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                        color: Theme.surfaceVariantText
                    }
                }

                Repeater {
                    model: Services.PangolinService.peers
                    delegate: Rectangle {
                        width: bodyCol.width
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainer
                        border.color: Theme.outline
                        border.width: 1
                        implicitHeight: 60

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: Theme.spacingS

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 18
                                color: Theme.surfaceContainerHighest
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
                                border.width: 1
                                DankIcon {
                                    anchors.centerIn: parent
                                    name: modelData.isRelay ? "hub" : "computer"
                                    size: 18
                                    color: modelData.isRelay ? "#E8C57A" : Theme.surfaceText
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Row {
                                    spacing: Theme.spacingXS
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.alias
                                        font.pixelSize: Theme.fontSizeSmall + 1
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                    }
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: modelData.isRelay
                                        width: relayLbl.implicitWidth + 10
                                        height: 16
                                        radius: 4
                                        color: Qt.rgba(0.91, 0.77, 0.48, 0.32)
                                        border.width: 1
                                        border.color: Qt.rgba(0.91, 0.77, 0.48, 0.55)
                                        StyledText {
                                            id: relayLbl
                                            anchors.centerIn: parent
                                            text: "RELAY"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            font.letterSpacing: 0.5
                                            color: "#FFD58A"
                                        }
                                    }
                                }
                                StyledText {
                                    text: modelData.ip || "—"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono, monospace"
                                    color: Theme.surfaceVariantText
                                }
                            }

                            Column {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                Row {
                                    spacing: 4
                                    anchors.right: parent.right
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: modelData.online ? "#9BD4A8" : Theme.surfaceVariantText
                                    }
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.rtt >= 0 ? modelData.rtt + "ms" : "—"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        font.family: "JetBrains Mono, monospace"
                                        color: Theme.surfaceText
                                    }
                                }
                                StyledText {
                                    anchors.right: parent.right
                                    text: (root.nowMs, root._fmtAgo(modelData.lastSeen))
                                    font.pixelSize: 9
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }
                    }
                }
            }

            // ---- Section: ROUTES ----
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: Services.PangolinService.state === "connected" ? Services.PangolinService.routes.length > 0 : Services.PangolinService.aliases.length > 0

                Item {
                    width: parent.width
                    height: 16
                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Services.PangolinService.state === "connected" ? "ROUTES" : "AVAILABLE ALIASES"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                        color: Theme.surfaceVariantText
                    }
                    DankIcon {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.routesExpanded ? "expand_more" : "expand_less"
                        size: 14
                        color: Theme.surfaceVariantText
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.routesExpanded = !root.routesExpanded
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.routesExpanded

                    Repeater {
                        model: Services.PangolinService.state === "connected" ? Services.PangolinService.routes : Services.PangolinService.aliases
                        delegate: Rectangle {
                            width: bodyCol.width
                            height: 36
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHigh
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingS
                                spacing: Theme.spacingS

                                DankIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    name: "alt_route"
                                    size: 14
                                    color: Theme.surfaceVariantText
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    font.family: "JetBrains Mono, monospace"
                                    color: Theme.primary
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: Services.PangolinService.state === "connected"
                                    width: tunnelLbl.implicitWidth + 12
                                    height: 18
                                    radius: 5
                                    color: Theme.primary
                                    StyledText {
                                        id: tunnelLbl
                                        anchors.centerIn: parent
                                        text: "VIA TUNNEL"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        font.letterSpacing: 0.5
                                        color: Theme.onPrimary
                                        font.family: "JetBrains Mono, monospace"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Footer ----
            Item {
                width: parent.width
                height: 28
                visible: !Services.PangolinService.cliMissing

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "smart_toy"
                        size: 12
                        color: Theme.surfaceVariantText
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Agent · " + (Services.PangolinService.agent || "Pangolin CLI")
                        font.pixelSize: 10
                        color: Theme.surfaceVariantText
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXS

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: settingsArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                        DankIcon {
                            anchors.centerIn: parent
                            name: "settings"
                            size: 14
                            color: Theme.surfaceText
                        }
                        MouseArea {
                            id: settingsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                PopoutService.openSettingsWithTab("Plugins");
                            }
                        }
                    }
                }
            }
        }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.nowMs = Date.now()
    }
}
