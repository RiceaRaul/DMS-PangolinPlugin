#!/usr/bin/env bash
# GUI password prompt for sudo (SUDO_ASKPASS).
# Picks first available helper.
set -e

PROMPT="${1:-Pangolin requires sudo password}"

for cmd in \
    "zenity --password --title=Pangolin --text=$PROMPT" \
    "kdialog --password $PROMPT" \
    "ksshaskpass $PROMPT" \
    "/usr/lib/ssh/x11-ssh-askpass $PROMPT" \
    "/usr/lib/openssh/gnome-ssh-askpass3 $PROMPT" \
    "/usr/lib/openssh/x11-ssh-askpass $PROMPT" \
    "/usr/libexec/openssh/x11-ssh-askpass $PROMPT" \
    "rofi -dmenu -password -p Pangolin"; do
    bin="${cmd%% *}"
    if command -v "$bin" >/dev/null 2>&1 || [ -x "$bin" ]; then
        exec $cmd
    fi
done

echo "no askpass helper found" >&2
exit 1
