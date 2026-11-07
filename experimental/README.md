# Persist Preconditioning: install that builds on the head unit

This is a second way to install Persist Preconditioning. The head unit builds the changed settings app itself during
the install, so there is nothing to build on your computer and no vehicle files to copy.

Experimental. Use at your own risk.

## Install

Get the package from `experimental/dist/` (or build it, see below), then install it over adb:

```sh
adb push experimental/dist/ev3-persist-experimental-0.1.0.zip /data/local/tmp/
adb shell /system/xbin/nemesis install /data/local/tmp/ev3-persist-experimental-0.1.0.zip
```

The install builds for a few minutes, then the head unit reboots.

## Check that it worked

- Open **EV Settings**. **Persist Preconditioning Mode** is under Battery Conditioning Mode.
- Read the log: `adb shell cat /data/nemesis/ev3.persist.experimental.log`

## Uninstall

```sh
adb shell /system/xbin/nemesis uninstall ev3.persist.experimental
adb shell reboot
```

The uninstall puts back the stock app from the backup in `/data/nemesis/backup/ev3.persist.experimental/`.

## If something goes wrong

- The install stops with a message in the log. Nothing is changed on the head unit when it stops before the reboot.
- If NEMESIS says the package is incompatible, check the `os` and `models` lines in `package/NEMESIS.data`.
- Do not install this and the original package together. Uninstall one before installing the other.

## Build the package yourself

You need a JDK, the Android SDK (for `d8` and `android.jar`), and `baksmali.jar` and `smali.jar` (2.5.x).

```sh
export BAKSMALI_JAR=/path/to/baksmali.jar
export SMALI_JAR=/path/to/smali.jar
export D8=$HOME/Library/Android/sdk/build-tools/36.0.0/d8
export ANDROID_JAR=$HOME/Library/Android/sdk/platforms/android-36/android.jar
sh experimental/build.sh 0.1.0
```

The zip is written to `experimental/dist/`.

## Tests

```sh
BAKSMALI_JAR=/path/to/baksmali.jar SMALI_JAR=/path/to/smali.jar sh experimental/tests/run_tests.sh
```

Third-party code in the package is listed in `THIRD_PARTY_NOTICES.md`.
