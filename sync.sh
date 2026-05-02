#!/usr/bin/env bash
# Sync PangolinWidget source -> DMS plugin directory.
# Usage: ./sync.sh [--watch]
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/DankMaterialShell/plugins/PangolinWidget"

sync_once() {
    mkdir -p "$DEST"
    rsync -a --delete \
        --exclude='.serena' \
        --exclude='.git' \
        --exclude='sync.sh' \
        --exclude='*.swp' \
        "$SRC/" "$DEST/"
    echo "[sync] $SRC -> $DEST"
}

if [[ "${1:-}" == "--watch" ]]; then
    command -v inotifywait >/dev/null || { echo "install inotify-tools"; exit 1; }
    sync_once
    while inotifywait -qq -r -e modify,create,delete,move "$SRC" --exclude '\.serena|sync\.sh'; do
        sync_once
    done
else
    sync_once
fi
