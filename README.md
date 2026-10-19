# Win11 Wired Network Tray Icons for KDE Plasma

A standalone KDE Plasma 6.7.x / 6.8.0 tweak that replaces the wired Ethernet tray glyphs used by the Networks applet with cleaner Win11-style monitor/network icons.

The mod keeps Plasma's normal network-state logic intact. It only remaps these wired states to dedicated tray assets:

- `network-wired-activated`
- `network-wired-activated-limited`
- `network-wired-activated-locked`
- `network-wired-available`

The patched applet maps those states to unique `win11-wired-*` icon names so KDE does not accidentally resolve duplicate icon names from another theme directory.

The included SVGs are tray-optimized 22x22 versions and are installed into both the Win11 theme's `status/22` and `status/24` directories.

## Requirements

- KDE Plasma 6.7.x or Plasma 6.8.0 (tested on CachyOS)
- `plasma-nm`
- a local icon theme named `Win11` at `~/.local/share/icons/Win11`
- Arch Linux / CachyOS-style `pacman` package metadata
- normal Plasma build dependencies for `plasma-nm`

Tested with `plasma-nm 6.7.4` / upstream tag `v6.7.4`.

**Plasma 6.8.0 port:** The icon-selection expression at `applet/main.qml:56` is unchanged upstream. The mod has been patched, built, installed, and verified successfully on CachyOS `plasma-nm 6.8.0-1.1` using the `plasma-6.8-port` branch. Plasma Shell initially failed to return with the legacy quit/replace restart procedure; restarting `plasma-plasmashell.service` through systemd recovered the panel, and the installer and restore scripts now use that method. A full restore/reinstall cycle also passed: `RESTORED BACKUP` returned the stock plugin SHA-256 `4efe27cbbb93da62e040ce5edffefce9bdfecce157eecdacac69b6cc16933358`, and a subsequent rebuild/reinstall returned `MOD INSTALLED`.

## Install

```bash
./scripts/install.sh --dry-run
# First managed install requires a verified stock networkmanagement plugin
# from exactly your installed plasma-nm version:
./scripts/install.sh --backup-from /path/to/verified-stock/org.kde.plasma.networkmanagement.so
./scripts/verify.sh
```

The installer:

- detects the installed `plasma-nm` version
- checks out the matching upstream Plasma tag
- preserves an immutable stock plugin backup supplied explicitly on first install (do not use a prior Plasma version's backup)
- applies the wired-icon mapping by exact-expression replacement
- builds only `org.kde.plasma.networkmanagement`
- installs the tray-optimized SVG assets
- installs the rebuilt applet plugin
- restarts Plasma and records the installed state

## After a plasma-nm update

A package update can overwrite the rebuilt applet plugin. Reapply the mod with:

```bash
./scripts/reapply.sh --dry-run
./scripts/reapply.sh
./scripts/verify.sh
```

The original managed stock backup is preserved rather than replaced by an already-modified plugin. If you upgraded from Plasma 6.7 to 6.8, archive the *entire* previous `~/.local/state/plasma-network-icon` directory before initial 6.8 installation, and obtain a verified 6.8 stock plugin backup first. Never reuse a 6.7 backup for 6.8.

## Restore stock Plasma behavior

```bash
./scripts/restore.sh
./scripts/verify.sh
```

The restore script reinstalls the saved stock `org.kde.plasma.networkmanagement.so` and removes the custom `win11-wired-*` SVG aliases installed by this project.

## Paths

Temporary source/build data:

```text
~/.cache/plasma-network-icon/
```

Persistent backup/state:

```text
~/.local/state/plasma-network-icon/
```

Stock Plasma NetworkManager applet plugin:

```text
/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so
```

## Patch reference

`patches/plasma-6.7-win11-wired-icons.patch` is kept as a human-readable reference showing the source change. The installer does **not** use `git apply`; it performs an exact-expression replacement so minor line-number changes do not break installation.

## Icon origin and modifications

The four SVG assets in `icons/` were derived from wired-network status icons shipped in a local icon theme named `Win11`.

The source theme's `COPYING` file identifies its license as the **GNU General Public License version 3 (GPL-3.0)**. The copies in this repository have been modified from the source-theme versions for KDE Plasma tray use, including resizing/reframing the artwork to a 22x22 canvas and renaming the files to unique `win11-wired-*` aliases.

The available `index.theme` metadata identifies the theme as `Win11` with the comment `MacOSX style icon theme for linux`, but does not contain an author, project URL, or other provenance information. If the original upstream theme source is identified, its author/project attribution should be added here.

This repository does not claim the SVG artwork as original artwork created for this project, and the name "Win11" is used only to describe the source theme/style. This project is not affiliated with or endorsed by Microsoft or KDE.

## License

The redistributed/modified icon artwork is covered by **GPL-3.0**, matching the license shipped with the source icon theme. Modified versions are explicitly identified above.

The scripts and supporting project files are also distributed under **GPL-3.0** for a simple, consistent repository license.
