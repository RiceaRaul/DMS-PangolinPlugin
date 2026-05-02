import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets
import "./services" as Services

PluginSettings {
    id: root
    pluginId: "pangolin-widget"

    StyledText {
        width: parent.width
        text: "Pangolin Widget"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Status, control, and peers for the Pangolin CLI"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Account ---
    StyledText {
        width: parent.width
        text: "Account"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        Rectangle {
            width: 12
            height: 12
            radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: Services.PangolinService.loggedIn ? "#9BD4A8" : Theme.surfaceVariantText
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Services.PangolinService.loggedIn ? ("Logged in" + (Services.PangolinService.org ? " · " + Services.PangolinService.org : "")) : "Not logged in"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        Rectangle {
            width: 120
            height: 36
            radius: Theme.cornerRadius
            color: loginArea.containsMouse ? Theme.primaryHover : Theme.primary
            visible: !Services.PangolinService.loggedIn

            StyledText {
                anchors.centerIn: parent
                text: "Login"
                color: Theme.onPrimary
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

        Rectangle {
            width: 120
            height: 36
            radius: Theme.cornerRadius
            color: logoutArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16) : Theme.errorHover
            visible: Services.PangolinService.loggedIn

            StyledText {
                anchors.centerIn: parent
                text: "Logout"
                color: Theme.error
                font.weight: Font.Medium
            }

            MouseArea {
                id: logoutArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.PangolinService.logout()
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Display ---
    StyledText {
        width: parent.width
        text: "Display"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "barMode"
        label: "Bar Indicator"
        description: "What to show in the bar pill"
        options: [
            {
                label: "Icon Only",
                value: "icon_only"
            },
            {
                label: "Icon + State",
                value: "icon_state"
            },
            {
                label: "Icon + Org",
                value: "icon_org"
            },
            {
                label: "Icon + Peers",
                value: "icon_peers"
            }
        ]
        defaultValue: "icon_state"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Polling ---
    StyledText {
        width: parent.width
        text: "Polling"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "popoutPollSec"
        label: "Active Poll Interval"
        description: "Status refresh rate while popout open or live RTT enabled"
        defaultValue: 3
        minimum: 1
        maximum: 10
        unit: "s"
    }

    SliderSetting {
        settingKey: "backgroundPollSec"
        label: "Background Poll Interval"
        description: "Status refresh rate when popout closed"
        defaultValue: 30
        minimum: 10
        maximum: 120
        unit: "s"
    }

    ToggleSetting {
        settingKey: "liveRTT"
        label: "Live RTT"
        description: "Always poll at active rate (more CPU)"
        defaultValue: false
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Notifications ---
    StyledText {
        width: parent.width
        text: "Notifications"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "muteAll"
        label: "Mute All"
        description: "Disable every Pangolin notification"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "notifyOnError"
        label: "Errors"
        description: "Notify when tunnel fails or auth breaks"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "notifyOnConnect"
        label: "Connected"
        description: "Notify when tunnel connects (only auto-connects unless 'Notify on user actions' is on)"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "notifyOnDisconnect"
        label: "Disconnected"
        description: "Notify when tunnel drops (unexpected disconnects only unless 'Notify on user actions' is on)"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "notifyOnUserActions"
        label: "Notify on User Actions"
        description: "Also notify when YOU click toggle on/off (otherwise these are silent)"
        defaultValue: false
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Privileges ---
    StyledText {
        width: parent.width
        text: "Privileges"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: Services.PangolinService.hasNopasswd ? "Passwordless sudo: enabled" : "Passwordless sudo: disabled (each up/down asks for password)"
        font.pixelSize: Theme.fontSizeSmall
        color: Services.PangolinService.hasNopasswd ? "#9BD4A8" : Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "Installs /etc/sudoers.d/pangolin-widget allowing pangolin up/down/status without password. One-time setup; requires sudo password once."
        font.pixelSize: Theme.fontSizeSmall - 1
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Row {
        width: parent.width
        spacing: Theme.spacingS

        Rectangle {
            width: 180
            height: 36
            radius: Theme.cornerRadius
            color: installArea.containsMouse ? Theme.primaryHover : Theme.primary
            visible: !Services.PangolinService.hasNopasswd

            StyledText {
                anchors.centerIn: parent
                text: "Install passwordless sudo"
                color: Theme.onPrimary
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                id: installArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.PangolinService.installSudoers()
            }
        }

        Rectangle {
            width: 140
            height: 36
            radius: Theme.cornerRadius
            color: removeArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16) : Theme.errorHover
            visible: Services.PangolinService.hasNopasswd

            StyledText {
                anchors.centerIn: parent
                text: "Remove sudoers"
                color: Theme.error
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                id: removeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.PangolinService.uninstallSudoers()
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    // --- Advanced ---
    StyledText {
        width: parent.width
        text: "Advanced"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "terminalCommand"
        label: "Terminal Command"
        description: "Override terminal used for `pangolin login` (leave blank to auto-detect)"
        placeholder: "kitty -e"
        defaultValue: ""
    }
}
