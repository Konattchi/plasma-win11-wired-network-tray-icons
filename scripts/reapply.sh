#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP="$HOME/.local/state/plasma-network-icon/org.kde.plasma.networkmanagement.so.backup"

if [[ ! -f "$BACKUP" ]]; then
    echo "Refusing reapply: managed stock backup does not exist." >&2
    echo "Run scripts/install.sh for the first managed installation." >&2
    exit 1
fi

if [[ "${1:-}" == "--dry-run" ]]; then
    "$ROOT/scripts/install.sh" --dry-run
else
    "$ROOT/scripts/install.sh"
fi
if [[ "${1:-}" != "--dry-run" ]]; then
    "$ROOT/scripts/verify.sh"
fi
