# Persist Preconditioning

A NEMESIS package for Hyundai and Kia EVs with a NEMESIS head unit. It adds a **Persist Preconditioning Mode** checkbox to EV Settings.

When Persist is checked, the head unit keeps **Battery Conditioning Mode** on. If Bluelink turns that mode off (for example, after a charge-limit change), the head unit turns it back on. The car still decides when to preheat. This package does not start preheating.

## Two ways to install (this branch has both)

This branch contains everything on `main` (the original method) plus a second, experimental method.

| | Original method | Experimental method |
|---|---|---|
| Where the patched app is built | On your computer, from your car's own files | On the head unit, during install |
| What you install | A package you build for your car | A ready-made package, `experimental/dist/` |
| Tested on a head unit | Yes, on one car | **No, not yet** |
| Risk | Lower | Higher: the first real test is the install itself |
| Where to start | The Quick start below | [`experimental/README.md`](experimental/README.md) |

If you want the method that has been run on a car, use the original method below. The experimental method is for
trying the on-device build, and its README lists what is and is not verified.

## Quick start

Once `build.env` is filled in and the head unit is connected over adb:

```sh
sh tools/pull_stock.sh                                   # copy stock files, print checksums
sh tools/build.sh 1.0                                    # build out/ev3-persist-1.0.zip
sh tools/install.sh out/ev3-persist-1.0.zip              # install over adb (reboots the head unit)
adb shell cat /data/nemesis/ev3.persist.preconditioning.log   # check the result
```

To install from a USB drive instead of adb:

```sh
sh tools/usb.sh out/ev3-persist-1.0.zip /Volumes/MYUSB   # then accept the prompt in NEMESIS on the head unit
```

To remove it: `sh tools/uninstall.sh`

The steps below explain each command.

## Read this first

- **Use at your own risk.** This changes software on a vehicle's head unit. A bad build or a failed install can leave it unusable.
- **Keep a backup.** Save the stock `HKMC_TAppEV3.apk` and `.odex` (steps 1 and 2 below) before you install.
- **It is tested on one vehicle only:** a CEEV.CAN Ioniq 6 head unit, build `CEEV.CAN.0000.V014.010.250818`. Other builds need their own payload.
- **Persist is on by default.** Installing turns it on.
- **Battery energy:** when the car preheats, that uses battery energy and can reduce range, especially in cold weather.
- **Limits:** the head unit only turns the mode back on when it sees the change go through the app. It tries at most three times in a row.
- **Uninstall does not reboot.** Reboot the head unit after you uninstall.

This project is not affiliated with Hyundai or Kia.

## What you need

- A head unit that runs NEMESIS, with `adb` access.
- On your computer: Java, `apktool`, `jarsigner`, `python3`, `zip`, and `adb`.
- A signing key of your own. Create one with:

  ```sh
  keytool -genkeypair -keystore my.keystore -alias myalias -keyalg RSA -keysize 2048 -validity 10000
  ```

## Steps

Run every command from the root of this repository.

### 1. Install the tools

**macOS** (with [Homebrew](https://brew.sh)):

```sh
brew install openjdk apktool python
brew install --cask android-platform-tools
```

`jarsigner` and `keytool` come with the JDK. `zip` is already on macOS. If `java` or `jarsigner` isn't found after installing, follow the message Homebrew prints to add the JDK to your PATH.

**Debian or Ubuntu Linux:**

```sh
sudo apt install openjdk-17-jdk apktool adb python3 zip
```

The `apktool` in some distributions is old. If the build fails inside apktool, install the current version from https://apktool.org.

**Smali tools (both platforms):** download `baksmali.jar` and `smali.jar` from the releases page at https://github.com/JesusFreke/smali/releases. Use the same version for both (2.x). Put them anywhere, then set their paths in `build.env`.

**The `lpatch` checksum tool:** not in this repository. Copy it into `package/bin/` and make it executable (`chmod +x package/bin/lpatch`).

Check the install:

```sh
java -version && apktool --version && jarsigner -help > /dev/null && adb version && python3 --version
```

### 2. Create your settings

```sh
cp build.env.example build.env
```

Open `build.env` and fill in the jar paths, your keystore, and the OS and MODEL of your head unit.

### 3. Copy the stock files from the head unit

Connect the head unit over adb, then run:

```sh
sh tools/pull_stock.sh
```

It copies the stock APK, odex, and framework into `stock/`, and prints the OS string to put in `build.env`. Keep a copy of `stock/` somewhere safe.

### 4. Build

```sh
sh tools/build.sh 1.0
```

This builds the patched app, signs it, and makes the install zip in `out/`. It also writes `out/NEMESIS.data` for a USB drive. If it stops, the message names a log in `build/` to read.

### 5. Install

Pick one:

- **Over adb:** `sh tools/install.sh out/ev3-persist-1.0.zip`
- **From a USB drive:** plug the drive in, find its folder (for example `/Volumes/MYUSB`), then run `sh tools/usb.sh out/ev3-persist-1.0.zip /Volumes/MYUSB`. Plug the drive into the head unit and accept the install prompt in NEMESIS.

The head unit reboots after installing.

### 6. Check that it worked

- Open **EV Settings**. You should see **Persist Preconditioning Mode** under Battery Conditioning Mode.
- Check the log: `adb shell cat /data/nemesis/ev3.persist.preconditioning.log`. The last line on a first install should say `installed - rebooting so Dalvik dexopts the patched APK`, and nothing should say `FAIL`.

### 7. Uninstall

```sh
sh tools/uninstall.sh
```

The uninstall puts back the stock APK and odex from the backup made at install time.

## If something goes wrong

- **The install prompt says the package is incompatible.** The `os` and `models` values in `package/NEMESIS.data` must match your head unit. Change them to the values NEMESIS reports for your unit.
- **The install fails right away.** Read `/data/nemesis/ev3.persist.preconditioning.log`. A message like `payload checksum mismatch` means the payload was built for a different stock file.
- **The EV Settings screen closes when you open it.** Uninstall the package, reboot, and report the log from `/data/nemesis/`.
- **You can't get the head unit to boot.** Use the uninstall or restore the stock APK and odex over adb, then reboot.

## Other vehicle builds

Each build needs its own payload, because the code names change between builds. Repeat steps 1 to 4 using that build's own stock files. Do not reuse a payload from another build.

When a patch fails on a new build, you will need to update the anchor text in `tools/smali/patch_*.py` or `tools/resources/patch_resources.py`. The repository tests check packaging and refusal behavior. They do not check the patches on a real build.

## Repository layout

| Path | What it is |
|---|---|
| `package/` | The NEMESIS package: descriptor, install, post-install, and uninstall scripts |
| `tools/pull_stock.sh` | Copies the stock files from the head unit |
| `tools/build.sh` | Builds the patched app and the install zip |
| `tools/install.sh`, `tools/uninstall.sh`, `tools/usb.sh` | Install, remove, or copy to USB |
| `tools/build_payload.sh` | The payload build that `build.sh` calls |
| `tools/make_package.sh` | Puts the patched app into the install zip |
| `tools/smali/` | Patches to the app's code |
| `tools/resources/patch_resources.py` | Patches to the layout, IDs, and strings |
| `tests/run_tests.sh` | Repository checks |

## License

MIT. See `LICENSE`.
