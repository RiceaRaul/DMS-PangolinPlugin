#!/usr/bin/env bash
# Install passwordless sudo entry for pangolin (opt-in).
# Restricts to up/down/status subcommands.
set -e

PANGOLIN=$(command -v pangolin || echo /usr/local/bin/pangolin)
[ -x "$PANGOLIN" ] || { echo "pangolin binary not found" >&2; exit 1; }

USERNAME=${SUDO_USER:-$USER}

TMP=$(mktemp)
cat > "$TMP" <<EOF
# Pangolin Widget — installed $(date -u +%Y-%m-%dT%H:%M:%SZ)
$USERNAME ALL=(root) NOPASSWD: $PANGOLIN up, $PANGOLIN up *, $PANGOLIN down, $PANGOLIN down *, $PANGOLIN status, $PANGOLIN status *
EOF

if [ "$(id -u)" -ne 0 ]; then
    sudo install -m 440 -o root -g root "$TMP" /etc/sudoers.d/pangolin-widget
else
    install -m 440 -o root -g root "$TMP" /etc/sudoers.d/pangolin-widget
fi
rm -f "$TMP"

if visudo -c -f /etc/sudoers.d/pangolin-widget >/dev/null 2>&1; then
    echo "OK: passwordless sudo installed for $USERNAME -> $PANGOLIN"
    exit 0
fi
echo "FAILED: visudo check failed; removing" >&2
sudo rm -f /etc/sudoers.d/pangolin-widget
exit 1
