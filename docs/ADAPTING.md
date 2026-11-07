# Adapting the payload to a new vehicle build

The patch matches exact class, method, and field names from one build's code. Hyundai/Kia rename these between builds (we hit this with a field that was named differently on another build). So each build needs its own payload, made from that build's own files.

## 1. Get the stock files from your head unit

You need the head unit's own copies, not files from another car. Use `adb` (or NEMESIS root) to copy:

- `/system/app/HKMC_TAppEV3.apk`
- `/system/app/HKMC_TAppEV3.odex`
- the whole `/system/framework/` folder

Record the head unit's build with `getprop ro.build.product` and the `os`/model values NEMESIS reports, so you can fill in the compatibility fields.

Check the sizes and checksums against what you pulled. The odex must belong to the APK.

## 2. Build the payload

```sh
export STOCK_APK=/path/to/HKMC_TAppEV3.apk
export STOCK_ODEX=/path/to/HKMC_TAppEV3.odex
export FRAMEWORK_DIR=/path/to/framework
export BAKSMALI_JAR=/path/to/baksmali.jar   # 2.x, used with -a 18
export SMALI_JAR=/path/to/smali.jar         # same version family
export KEYSTORE=/path/to/your.keystore      # make your own key
export KEY_ALIAS=yourAlias
export KEY_PASS=yourPassword
sh tools/build_payload.sh
```

Run these commands from the repository root. The output lands in `build/` (or `$WORK_DIR`).

The script stops at the first problem and names the log to read. The most common failures:

- **`patch ... failed`** — a class, method, or field name is different in this build. Open `tools/smali/patch_*.py`, find the anchor that failed, and update it for this build's names.
- **`baksmali skipped classes`** — the framework folder doesn't match the odex. Re-pull the framework from the same head unit.
- **`anchor ... found N times`** — the resource patch matched more than once or not at all. Check `tools/resources/patch_resources.py` against this build's layout.

## 3. Make the install zip

```sh
mkdir -p out
sh tools/make_package.sh build/HKMC_TAppEV3.patched.apk <stock_apk_md5> <stock_odex_md5> 1.0 out/ev3-persist-1.0.zip
```

The script refuses to package unless `package/bin/lpatch` is present and executable.

## 4. Check before you install

- `sh tests/run_tests.sh` passes. Note that these tests do not check the payload or the device.
- The `os` and `models` fields in `package/NEMESIS.data` match your head unit.
- You have a backup of the stock APK and odex from step 1.
- You understand that re-signing with your own key is unverified on your head unit.
- If the head unit is left in a bad state, you can restore the stock files by hand over adb or by using NEMESIS uninstall.
- You know how to reach the head unit's logs (`/data/nemesis/`) if the install fails.

## What a new build needs

Each build needs its own run through steps 1–3. Nothing here guarantees that a patch that worked on one build will work on another, even if the screens look the same.
