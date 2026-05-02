#!/usr/bin/env bash
set -e
if [ "$(id -u)" -ne 0 ]; then
    sudo rm -f /etc/sudoers.d/pangolin-widget
else
    rm -f /etc/sudoers.d/pangolin-widget
fi
echo "OK: passwordless sudo removed"
