# Plasma 6.8.0 compatibility release

## What's new
- Adds tested Plasma NM 6.8.0 support while retaining Plasma 6.7.x.
- Includes a contextual 6.8 reference patch for Win11 wired-network states.
- Validates original-plugin backup and package version for restoration.
- Uses the Plasma Shell systemd user service for reliable installation/restoration restart.
- Correctly reports `RESTORED BACKUP` when custom icon assets were removed.

## Validated
- CachyOS `plasma-nm 6.8.0-1.1`.
- Patch application, isolated build, managed installation, `verify.sh`, stock restore, reinstall, `reapply.sh --dry-run`, and `reapply.sh` passed.
- User confirmed expected runtime behavior, and the original 6.8 plugin backup remained unchanged.

## Important
- Supports Plasma 6.7.x and **exactly** 6.8.0; newer versions need separate validation.
- First managed installation on 6.8.0 requires a verified stock networkmanagement plugin matching the installed package. Never reuse a 6.7 backup.
- Requires the local `Win11` icon theme and an Arch/CachyOS-style environment.

See README for install, verify, reapply, and restore instructions.
