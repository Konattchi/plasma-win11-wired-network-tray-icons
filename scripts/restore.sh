#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/plasma-network-icon"
PLUGIN="/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so"
BACKUP="$STATE/org.kde.plasma.networkmanagement.so.backup"

if [[ ! -f "$BACKUP" ]]; then
    echo "No managed stock backup found: $BACKUP" >&2
    exit 1
fi

sudo install -m 0755 "$BACKUP" "$PLUGIN"

for dir in \
    "$HOME/.local/share/icons/Win11/status/22" \
    "$HOME/.local/share/icons/Win11/status/24"
do
    rm -f \
        "$dir/win11-wired-activated.svg" \
        "$dir/win11-wired-activated-limited.svg" \
        "$dir/win11-wired-activated-locked.svg" \
        "$dir/win11-wired-available.svg"
done

rm -f "$HOME/.cache/icon-cache.kcache"

kquitapp6 plasmashell >/dev/null 2>&1 || true
(plasmashell --replace >/dev/null 2>&1 &) || true

echo "Restored stock plasma-nm applet."
echo "Current plugin SHA-256: $(sha256sum "$PLUGIN" | awk '{print $1}')"
