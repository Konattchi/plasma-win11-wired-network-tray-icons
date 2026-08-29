#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/plasma-network-icon"
PLUGIN="/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so"
BACKUP="$STATE/org.kde.plasma.networkmanagement.so.backup"
STATE_ENV="$STATE/state.env"

if [[ ! -f "$BACKUP" ]]; then
    echo "Managed backup: MISSING"
    exit 1
fi

current="$(sha256sum "$PLUGIN" | awk '{print $1}')"
backup="$(sha256sum "$BACKUP" | awk '{print $1}')"

echo "Current plugin SHA-256: $current"
echo "Backup plugin SHA-256:  $backup"

if [[ -f "$STATE_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_ENV"
    echo "Recorded mod SHA-256:   ${PLUGIN_SHA256:-unknown}"
    if [[ "$current" == "${PLUGIN_SHA256:-}" ]]; then
        echo "State: MOD INSTALLED"
    elif [[ "$current" == "$backup" ]]; then
        echo "State: RESTORED BACKUP"
    else
        echo "State: DIFFERENT/UPDATED PLUGIN"
    fi
else
    if [[ "$current" == "$backup" ]]; then
        echo "State: RESTORED BACKUP"
    else
        echo "State: NO RECORDED MOD STATE"
    fi
fi

missing=0
for size in 22 24; do
    for icon in \
        win11-wired-activated.svg \
        win11-wired-activated-limited.svg \
        win11-wired-activated-locked.svg \
        win11-wired-available.svg
    do
        path="$HOME/.local/share/icons/Win11/status/$size/$icon"
        if [[ ! -f "$path" ]]; then
            echo "Missing icon: $path"
            missing=1
        fi
    done
done
exit "$missing"
