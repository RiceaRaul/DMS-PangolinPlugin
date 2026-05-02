import QtQuick
import qs.Common

Rectangle {
    id: root

    property string state: "disconnected"
    property bool animated: true
    property int dotSize: 8

    width: dotSize
    height: dotSize
    radius: dotSize / 2

    color: {
        switch (root.state) {
        case "connected":
            return "#9BD4A8";
        case "connecting":
            return "#E8C57A";
        case "error":
            return Theme.error;
        case "empty":
            return "transparent";
        default:
            return Theme.surfaceVariantText;
        }
    }
    border.width: root.state === "empty" ? 1 : 0
    border.color: Theme.surfaceVariantText

    SequentialAnimation on opacity {
        running: root.animated && root.state === "connecting"
        loops: Animation.Infinite
        NumberAnimation {
            from: 1
            to: 0.35
            duration: 600
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            from: 0.35
            to: 1
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
        }
    }
}
