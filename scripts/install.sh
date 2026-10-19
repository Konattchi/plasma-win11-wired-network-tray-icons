#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$HOME/.local/state/plasma-network-icon"
WORK="$HOME/.cache/plasma-network-icon"
SRC="$WORK/plasma-nm"
BUILD="$WORK/build"
PLUGIN="/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so"
BACKUP="$STATE/org.kde.plasma.networkmanagement.so.backup"
PATCH="$ROOT/patches/plasma-6.7-win11-wired-icons.patch" # Reference mapping; replacement is exact-expression based.
ICON22="$HOME/.local/share/icons/Win11/status/22"
ICON24="$HOME/.local/share/icons/Win11/status/24"

DRY_RUN=0
BACKUP_FROM=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --backup-from)
            [[ $# -ge 2 ]] || { echo "Missing path after --backup-from" >&2; exit 2; }
            BACKUP_FROM="$2"
            shift 2
            ;;
        *) echo "Usage: $0 [--dry-run] [--backup-from /path/to/stock/plugin.so]" >&2; exit 2 ;;
    esac
done

if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer expects an Arch/CachyOS-style system with pacman." >&2
    exit 1
fi

pkgver="$(pacman -Q plasma-nm | awk '{print $2}')"
upstream_ver="${pkgver%%-*}"
tag="v${upstream_ver}"
if [[ "$upstream_ver" == "6.8.0" ]]; then
    PATCH="$ROOT/patches/plasma-6.8-win11-wired-icons.patch"
fi

echo "plasma-nm package: $pkgver"
echo "Upstream source tag: $tag"
echo "Plugin: $PLUGIN"

if [[ "$upstream_ver" != 6.7.* && "$upstream_ver" != "6.8.0" ]]; then
    echo "Refusing unsupported Plasma NM version $upstream_ver. Supports 6.7.x and 6.8.0." >&2
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

if [[ -n "$BACKUP_FROM" && ! -f "$BACKUP_FROM" ]]; then
    echo "Stock backup path not found: $BACKUP_FROM" >&2
    exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Stock plugin source for first install: ${BACKUP_FROM:-NOT PROVIDED}"
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

# Validate managed backup before cloning, building, or altering the icon theme.
if [[ -f "$BACKUP" ]]; then
    if [[ -n "$BACKUP_FROM" ]] && ! cmp -s "$BACKUP_FROM" "$BACKUP"; then
        echo "ERROR: supplied stock backup differs from existing managed backup." >&2
        exit 1
    fi
    if [[ -f "$STATE/state.env" ]]; then
        recorded_tag="$(sed -n "s/^SOURCE_TAG='\\([^']*\\)'$/\\1/p" "$STATE/state.env")"
        if [[ -n "$recorded_tag" && "$recorded_tag" != "$tag" ]]; then
            echo "ERROR: managed backup belongs to $recorded_tag, not $tag." >&2
            exit 1
        fi
    fi
elif [[ -z "$BACKUP_FROM" ]]; then
    echo "ERROR: first managed install requires a verified stock backup via --backup-from." >&2
    exit 1
fi

mkdir -p "$STATE" "$WORK" "$ICON22" "$ICON24"

rm -rf "$SRC" "$BUILD"
git clone --depth 1 --branch "$tag" https://github.com/KDE/plasma-nm.git "$SRC"

cd "$SRC"

# Patch the verified stock Plasma 6.7.x / 6.8.0 icon expression without depending on
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
    if [[ -z "$BACKUP_FROM" ]]; then
        echo "ERROR: first managed install requires --backup-from with a verified stock plugin of version $upstream_ver." >&2
        echo "Do not use an old Plasma 6.7 backup for Plasma 6.8." >&2
        exit 1
    fi
    install -m 0644 "$BACKUP_FROM" "$BACKUP"
    echo "Created immutable stock backup: $BACKUP"
else
    if [[ -n "$BACKUP_FROM" && "$(sha256sum "$BACKUP_FROM" | cut -d' ' -f1)" != "$(sha256sum "$BACKUP" | cut -d' ' -f1)" ]]; then
        echo "ERROR: --backup-from conflicts with existing managed backup. Preserve/archive old state first." >&2
        exit 1
    fi
    if [[ -f "$STATE/state.env" ]]; then
        recorded_tag="$(sed -n "s/^SOURCE_TAG='\\([^']*\\)'$/\\1/p" "$STATE/state.env")"
        if [[ -n "$recorded_tag" && "$recorded_tag" != "$tag" ]]; then
            echo "ERROR: managed backup belongs to $recorded_tag, not $tag. Archive the old state and provide a matching stock backup." >&2
            exit 1
        fi
    fi
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

if ldd "$BUILT" | grep -q "not found"; then
    echo "ERROR: unresolved dependencies in built plugin." >&2
    exit 1
fi

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
