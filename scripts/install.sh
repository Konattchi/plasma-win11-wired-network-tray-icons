#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$HOME/.local/state/plasma-network-icon"
WORK="$HOME/.cache/plasma-network-icon"
SRC="$WORK/plasma-nm"
BUILD="$WORK/build"
PLUGIN="/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so"
BACKUP="$STATE/org.kde.plasma.networkmanagement.so.backup"
PATCH="$ROOT/patches/plasma-6.7-win11-wired-icons.patch"
ICON22="$HOME/.local/share/icons/Win11/status/22"
ICON24="$HOME/.local/share/icons/Win11/status/24"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer expects an Arch/CachyOS-style system with pacman." >&2
    exit 1
fi

pkgver="$(pacman -Q plasma-nm | awk '{print $2}')"
upstream_ver="${pkgver%%-*}"
tag="v${upstream_ver}"

echo "plasma-nm package: $pkgver"
echo "Upstream source tag: $tag"
echo "Plugin: $PLUGIN"

if [[ "$upstream_ver" != 6.7.* ]]; then
    echo "Refusing untested Plasma NM series $upstream_ver. This package is for 6.7.x." >&2
    exit 1
fi

if [[ ! -f "$PLUGIN" ]]; then
    echo "Plugin not found: $PLUGIN" >&2
    exit 1
fi

if [[ ! -f "$PATCH" ]]; then
    echo "Patch not found: $PATCH" >&2
    exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Patch SHA-256: $(sha256sum "$PATCH" | awk '{print $1}')"
    if [[ -f "$BACKUP" ]]; then
        echo "Managed stock backup: present"
        echo "Backup SHA-256: $(sha256sum "$BACKUP" | awk '{print $1}')"
    else
        echo "Managed stock backup: not created yet"
    fi
    echo "DRY RUN COMPLETE. Nothing was changed."
    exit 0
fi

mkdir -p "$STATE" "$WORK" "$ICON22" "$ICON24"

rm -rf "$SRC" "$BUILD"
git clone --depth 1 --branch "$tag" https://github.com/KDE/plasma-nm.git "$SRC"

cd "$SRC"

# Patch the exact stock Plasma 6.7.x icon expression without depending on
# surrounding whitespace/line numbers in a unified diff.
python - "$SRC/applet/main.qml" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = 'Plasmoid.icon: inPanel ? connectionIconProvider.connectionIcon + "-symbolic" : connectionIconProvider.connectionTooltipIcon'
new = 'Plasmoid.icon: inPanel ? (connectionIconProvider.connectionIcon === "network-wired-activated" ? "win11-wired-activated" : connectionIconProvider.connectionIcon === "network-wired-activated-limited" ? "win11-wired-activated-limited" : connectionIconProvider.connectionIcon === "network-wired-activated-locked" ? "win11-wired-activated-locked" : connectionIconProvider.connectionIcon === "network-wired-available" ? "win11-wired-available" : connectionIconProvider.connectionIcon + "-symbolic") : connectionIconProvider.connectionTooltipIcon'

count = s.count(old)
if count != 1:
    raise SystemExit(f"Expected exactly one stock Plasma icon expression, found {count}; refusing to modify source.")

p.write_text(s.replace(old, new, 1))
print("Patched applet/main.qml")
PY

cmake -S . -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF

cmake --build "$BUILD" \
    --target org.kde.plasma.networkmanagement \
    -j"$(nproc)"

BUILT="$BUILD/bin/plasma/applets/org.kde.plasma.networkmanagement.so"
if [[ ! -f "$BUILT" ]]; then
    echo "Build completed but applet plugin was not found: $BUILT" >&2
    exit 1
fi

if [[ ! -f "$BACKUP" ]]; then
    cp "$PLUGIN" "$BACKUP"
    chmod 0644 "$BACKUP"
    echo "Created immutable stock backup: $BACKUP"
else
    echo "Existing stock backup preserved: $BACKUP"
fi

# Install the exact tray-optimized assets under unique names.
# Put identical optimized SVGs in both size directories so KDE resolves them
# consistently regardless of the icon size requested by the panel.
for icon in \
    win11-wired-activated.svg \
    win11-wired-activated-limited.svg \
    win11-wired-activated-locked.svg \
    win11-wired-available.svg
do
    install -m 0644 "$ROOT/icons/$icon" "$ICON22/$icon"
    install -m 0644 "$ROOT/icons/$icon" "$ICON24/$icon"
done

sudo install -m 0755 "$BUILT" "$PLUGIN"

rm -f "$HOME/.cache/icon-cache.kcache"

plugin_sha="$(sha256sum "$PLUGIN" | awk '{print $1}')"
backup_sha="$(sha256sum "$BACKUP" | awk '{print $1}')"
patch_sha="$(sha256sum "$PATCH" | awk '{print $1}')"

cat > "$STATE/state.env" <<EOF
PLASMA_NM_PACKAGE='$pkgver'
SOURCE_TAG='$tag'
PLUGIN_SHA256='$plugin_sha'
BACKUP_SHA256='$backup_sha'
PATCH_SHA256='$patch_sha'
EOF

kquitapp6 plasmashell >/dev/null 2>&1 || true
(plasmashell --replace >/dev/null 2>&1 &) || true

echo
echo "Installed."
echo "Modified plugin SHA-256: $plugin_sha"
echo "Stock backup SHA-256:    $backup_sha"
