#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/plasma-network-icon"
PLUGIN="/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so"
BACKUP="$STATE/org.kde.plasma.networkmanagement.so.backup"

if [[ ! -f "$BACKUP" ]]; then
    echo "No managed stock backup found: $BACKUP" >&2
    exit 1
fi

STATE_ENV="$STATE/state.env"
if [[ ! -f "$STATE_ENV" ]]; then
    echo "Refusing restoration: managed state is missing." >&2
    exit 1
fi
# State is written by this installer; validate its recorded backup and version.
# shellcheck disable=SC1090
source "$STATE_ENV"
actual_backup_sha="$(sha256sum "$BACKUP" | awk '{print $1}')"
if [[ "$actual_backup_sha" != "${BACKUP_SHA256:-}" ]]; then
    echo "Refusing restoration: stock backup checksum mismatch." >&2
    exit 1
fi
current_pkg="$(pacman -Q plasma-nm | awk '{print $2}')"
current_tag="v${current_pkg%%-*}"
if [[ "$current_tag" != "${SOURCE_TAG:-}" ]]; then
    echo "Refusing restoration: saved backup is for ${SOURCE_TAG:-unknown}, installed plasma-nm is $current_tag." >&2
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

systemctl --user restart plasma-plasmashell.service

echo "Restored stock plasma-nm applet."
echo "Current plugin SHA-256: $(sha256sum "$PLUGIN" | awk '{print $1}')"
