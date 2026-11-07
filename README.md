# Persist Preconditioning

A NEMESIS package for Hyundai and Kia EVs with a NEMESIS head unit. It adds a **Persist Preconditioning Mode** checkbox to EV Settings.

When Persist is checked, the head unit keeps **Battery Conditioning Mode** on. If Bluelink turns that mode off (for example, after a charge-limit change), the head unit turns it back on. The car still decides when to preheat. This package does not start preheating.

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
- The `lpatch` checksum tool. It is not in this repository. Copy it into `package/bin/` and make it executable.
- A signing key of your own. Create one with:

  ```sh
  keytool -genkeypair -keystore my.keystore -alias myalias -keyalg RSA -keysize 2048 -validity 10000
  ```

## Steps

Run every command from the root of this repository.

### 1. Copy the stock files from the head unit

```sh
mkdir -p stock/framework
adb pull /system/app/HKMC_TAppEV3.apk stock/
adb pull /system/app/HKMC_TAppEV3.odex stock/
adb pull /system/framework/ stock/
```

The framework files end up in `stock/framework/framework/`. If `HKMC_TAppEV3.odex` is missing, a Persist install is already on the unit. Uninstall it first (step 6), then copy again.

### 2. Record the stock checksums

On a Mac, use `md5 -q`. On Linux, use `md5sum`.

```sh
md5 -q stock/HKMC_TAppEV3.apk
md5 -q stock/HKMC_TAppEV3.odex
```

Keep both values. You need them in step 4.

### 3. Build the patched app

```sh
export STOCK_APK=stock/HKMC_TAppEV3.apk
export STOCK_ODEX=stock/HKMC_TAppEV3.odex
export FRAMEWORK_DIR=stock/framework/framework
export BAKSMALI_JAR=/path/to/baksmali.jar   # version 2.x
export SMALI_JAR=/path/to/smali.jar         # same version family
export KEYSTORE=my.keystore
export KEY_ALIAS=myalias
export KEY_PASS=yourpassword
sh tools/build_payload.sh
```

When it finishes, it prints the patched file and its checksum. The output is in `build/`.

If it stops, the message names a log to read. In `build/`, the most useful logs are `baksmali.log`, `smali.log`, and `apktool-b.log`. A failure in a smali or resource patch usually means this build uses different names from the one this project was written for. The patch scripts in `tools/` say which anchor failed.

### 4. Make the install package

```sh
mkdir -p out
sh tools/make_package.sh build/HKMC_TAppEV3.patched.apk <stock-apk-md5> <stock-odex-md5> 1.0 out/ev3-persist-1.0.zip
```

Use the checksums from step 2. The script refuses to run if `package/bin/lpatch` is missing.

### 5. Install it

Choose one.

**From a USB drive:**

1. Copy `out/ev3-persist-1.0.zip` to the root of a USB drive.
2. Create `NEMESIS.data` on the same drive with these lines:

   ```ini
   [nemesis]
   version=1.0
   type=install
   path=ev3-persist-1.0.zip
   ```

3. Plug the drive into the head unit, open NEMESIS, and accept the install prompt.

**Over adb:**

```sh
adb push out/ev3-persist-1.0.zip /data/local/tmp/
adb shell /system/xbin/nemesis install /data/local/tmp/ev3-persist-1.0.zip
```

Installing triggers a reboot. Wait for the head unit to come back up.

### 6. Check that it worked

- Open **EV Settings**. You should see **Persist Preconditioning Mode** under Battery Conditioning Mode.
- Check the log on the head unit:

  ```sh
  adb shell cat /data/nemesis/ev3.persist.preconditioning.log
  ```

  The last line should say `installed - rebooting so Dalvik dexopts the patched APK` on the first install, and nothing should say `FAIL`.

### 7. Uninstall

```sh
adb shell /system/xbin/nemesis uninstall ev3.persist.preconditioning
adb shell reboot
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
| `tools/build_payload.sh` | Builds the patched app from one build's stock files |
| `tools/make_package.sh` | Puts the patched app into the install zip |
| `tools/smali/` | Patches to the app's code |
| `tools/resources/patch_resources.py` | Patches to the layout, IDs, and strings |
| `tests/run_tests.sh` | Repository checks |

## License

MIT. See `LICENSE`.
