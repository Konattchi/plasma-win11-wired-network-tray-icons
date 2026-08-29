# Win11 Wired Network Tray Icons for KDE Plasma

A standalone KDE Plasma 6.7.x tweak that replaces the wired Ethernet tray glyphs used by the Networks applet with cleaner Win11-style monitor/network icons.

The mod keeps Plasma's normal network-state logic intact. It only remaps these wired states to dedicated tray assets:

- `network-wired-activated`
- `network-wired-activated-limited`
- `network-wired-activated-locked`
- `network-wired-available`

The patched applet maps those states to unique `win11-wired-*` icon names so KDE does not accidentally resolve duplicate icon names from another theme directory.

The included SVGs are tray-optimized 22x22 versions and are installed into both the Win11 theme's `status/22` and `status/24` directories.

## Requirements

- KDE Plasma 6.7.x
- `plasma-nm`
- a local icon theme named `Win11` at `~/.local/share/icons/Win11`
- Arch Linux / CachyOS-style `pacman` package metadata
- normal Plasma build dependencies for `plasma-nm`

Tested with `plasma-nm 6.7.4` / upstream tag `v6.7.4`.

## Install

```bash
./scripts/install.sh --dry-run
./scripts/install.sh
./scripts/verify.sh
```

The installer:

- detects the installed `plasma-nm` version
- checks out the matching upstream Plasma tag
- preserves an immutable stock plugin backup
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

The original managed stock backup is preserved rather than replaced by an already-modified plugin.

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
