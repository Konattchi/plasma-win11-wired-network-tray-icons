# Plasma Network Icon Mod

Standalone Plasma 6.7.x tweak for the KDE Networks applet.

It keeps Plasma's normal network-state logic, but for the wired states below it
uses dedicated Win11-theme tray assets instead of the cable-style/symbolic icons:

- network-wired-activated
- network-wired-activated-limited
- network-wired-activated-locked
- network-wired-available

The patched applet maps those states to unique `win11-wired-*` icon names.
The included SVGs are the tray-optimized versions.

## Paths

Temporary source/build:
`~/.cache/plasma-network-icon/`

Persistent backup/state:
`~/.local/state/plasma-network-icon/`

Stock plugin:
`/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.networkmanagement.so`

## Install

```bash
./scripts/install.sh --dry-run
./scripts/install.sh
./scripts/verify.sh
```

## After a plasma-nm package update

```bash
./scripts/reapply.sh --dry-run
./scripts/reapply.sh
```

The immutable stock backup is preserved.

## Restore

```bash
./scripts/restore.sh
./scripts/verify.sh
```

The restore script also removes the custom `win11-wired-*` assets installed in
the Win11 theme's `status/22` and `status/24` directories.

Tested while developing against plasma-nm 6.7.4 / upstream tag v6.7.4.

Installer note: source modification is performed by exact-expression replacement rather than line-number-sensitive `git apply`, while the patch file remains included as documentation of the change.
