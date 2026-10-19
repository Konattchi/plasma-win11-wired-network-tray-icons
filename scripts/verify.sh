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

state_label=""
if [[ -f "$STATE_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_ENV"
    echo "Recorded mod SHA-256:   ${PLUGIN_SHA256:-unknown}"
    if [[ "$current" == "${PLUGIN_SHA256:-}" ]]; then
        state_label="MOD INSTALLED"
        echo "State: $state_label"
    elif [[ "$current" == "$backup" ]]; then
        state_label="RESTORED BACKUP"
        echo "State: $state_label"
    else
        state_label="DIFFERENT/UPDATED PLUGIN"
        echo "State: $state_label"
    fi
else
    if [[ "$current" == "$backup" ]]; then
        echo "State: RESTORED BACKUP"
    else
        state_label="NO RECORDED MOD STATE"
        echo "State: $state_label"
    fi
fi

if [[ -f "$STATE_ENV" && -n "${BACKUP_SHA256:-}" && "$backup" != "$BACKUP_SHA256" ]]; then
    echo "ERROR: managed stock backup does not match recorded checksum." >&2
    exit 1
fi

# A successful restoration deliberately removes project-specific icons.
# Missing icons are an error only while the modified plugin is installed.
if [[ "$state_label" == "RESTORED BACKUP" ]]; then
    exit 0
fi
if [[ "$state_label" != "MOD INSTALLED" ]]; then
    exit 1
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
