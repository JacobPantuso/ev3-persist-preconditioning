# Persist Preconditioning (EV settings, head unit)

A NEMESIS install package for Hyundai/Kia head units that adds a **Persist Preconditioning Mode** checkbox to the EV settings screen. When Persist is on, the head unit keeps battery conditioning mode on, and locks the original checkbox so the setting can't be changed by mistake.

> **Warning**
>
> - This forces battery conditioning on. That uses battery energy and can shorten range, especially in cold weather.
> - It modifies vehicle systems. A bad build, a bad install, or a failed reboot can leave a head unit in a broken state.
> - It has been tested on one vehicle only (a CEEV.CAN Ioniq 6 head unit, build `CEEV.CAN.0000.V014.010.250818`). Other builds need their own payload.
> - Use it at your own risk. Keep a backup of your stock files before you install anything.

## How it behaves (read this first)

- **Persist is on by default.** Installing the package turns it on, which forces battery conditioning on. Uncheck Persist to stop the forcing.
- **The forcing has limits.** It writes "on" at most three times in a row before it stops. It only catches writes made through this app's own write path. A change that reaches the car some other way is not caught.
- **The original checkbox is locked while Persist is on.** Uncheck Persist first to change the mode.
- **Uninstall does not reboot.** The restored stock code keeps running until the head unit restarts.
- **Signing:** the payload is re-signed with your key. This is unverified on every head unit; if the app fails to start after install, the uninstall restores stock.

This project is not affiliated with Hyundai or Kia.

## What is in this repository

| Path | What it is |
|---|---|
| `package/` | The NEMESIS package template: descriptor, install, post-install, and uninstall scripts. |
| `tools/build_payload.sh` | Builds a patched APK from one vehicle's own stock files. |
| `tools/smali/` | Patches the app's code (deodexed smali). Each script stops if an anchor is missing. |
| `tools/resources/patch_resources.py` | Patches the layout, IDs, and strings. Stops if an anchor is missing. |
| `tools/make_package.sh` | Puts a built payload into the package and writes the checksums and version. |
| `tests/run_tests.sh` | Repository checks: syntax, the resource patch's refusal behavior, packaging, and hygiene. |
| `docs/ADAPTING.md` | Step-by-step guide for building the payload for your own vehicle. |

This repository does not contain Hyundai's app, odex, or framework files, or any signing key. Those come from your own head unit.

## Install (once you have a payload)

1. Put the package zip on a USB drive at the root, with a `NEMESIS.data` that points at it (`type=install`, `path=<zip name>`).
2. Plug the drive into the head unit and accept the install prompt in NEMESIS.
3. Let the head unit reboot. Logs are written to `/data/nemesis/ev3.persist.preconditioning.log` and to a `EV3_PERSIST_*` folder on the drive.

To remove it, use the NEMESIS uninstall. The uninstall restores the stock APK and odex from the backup made at install.

## Requirements

- A NEMESIS-capable head unit (the package uses NEMESIS remount and `lpatch`).
- `package/bin/lpatch` (the head unit's checksum tool). It is not included here. Copy it from a source you are licensed to use.
- For building: Java, `apktool`, `jarsigner`, `python3`, and `zip`.

## Status

Verified only on the one build listed above, by one person, on one car. The repository tests check packaging and refusal behaviour; they do not run the smali or resource patches against a real build, and they do not test the device. See `docs/ADAPTING.md` for what to check before you trust a new build.

## License

Released under the MIT License. See `LICENSE`.
