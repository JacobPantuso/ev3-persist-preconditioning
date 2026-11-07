# Experimental: install that rebuilds the app on the head unit

This is a second way to get Persist Preconditioning onto a head unit. The original method (the rest of this
repository) builds a patched app on a computer from your car's own files. This one does the whole build **on
the head unit**, so the package can be shared without any vehicle files in it and installed straight from NEMESIS.

> **More risk than the original method.** It has been run on a normal JVM against two real builds' files, but
> **not yet on a head unit.** The first real test is the install itself. Read "What is verified" before using it.

## How it differs from the original method

| | Original method | Experimental (this branch) |
|---|---|---|
| Where the patched app is built | On your computer | On the head unit, during install |
| What the package contains | Your build's patched app, made from your car's files | Only our scripts, our tools, and the helper code. No vendor files |
| New checkbox row | A layout edited with apktool | Built in code at run time by a small helper |
| Needs Java, apktool, a key on your computer | Yes | No (to install). Only to rebuild the package |
| Works on a build it has not seen | No, each build needs its own payload | It tries, and refuses cleanly if the app is not what it expects |
| Signing | A key you make | A new throwaway key made on the head unit |
| Strings | In the app's resources | English only, in the helper |
| Tested on a head unit | Yes (one car) | **No** |

## How it works

All of this runs in `scripts/pre.sh` as a scratch build, so a failure stops the install with `/system` untouched:

1. **Self-test.** The tools run on tiny sample data first: assemble, pack, sign, verify. If the head unit cannot run them, the install stops here.
2. **Checks.** The app must be an unmodified pair: an APK with no dex in it, and its odex present.
3. **Deodex.** The head unit's own odex is turned into smali, resolved against its own framework.
4. **Patch.** The patch engine adds the feature. It finds each hook by structure and string literals, not by obfuscated names, and stops if one is missing or ambiguous:
   - the data-store write for the battery conditioning key is wrapped so the value can be kept on;
   - the end of the battery conditioning row's constructor gets one call that builds the Persist row;
   - the settings service's `onCreate` gets one call that loads the saved value;
   - a small `Bridge` class is generated so the UI can write "on" through the app's own method.
5. **Assemble, pack, sign, verify.** The result is a new APK with every original resource, a new `classes.dex`, and a fresh signature. The same check the package installer applies (every entry's digest and signature) is run on it.

Only then does `scripts/post.sh` touch `/system`: it backs up the stock APK and odex with their checksums, copies the new
APK in, removes the stock odex (so Dalvik optimizes the new APK on boot), and reboots. If any step fails it puts the stock files back.

The Persist row, the scroll wrapper, trimming the stock description, and locking the stock row are all created at run time by
`PersistUi`. It looks everything up by resource name, and every entry point catches all exceptions, so a bug falls back to the
stock screen.

## What is verified

On a normal JVM (not a head unit), against the files of two real builds (a CEEV.CAN build and a US build):

- deodex output is identical to the `baksmali` command line's output for the CEEV.CAN build's files (the US build's output was not compared, only patched and verified);
- the patch engine finds all four hooks in both builds, the patched tree assembles, and the packed, signed APK verifies with
  our verifier, the JDK's `jarsigner`, and Android's `apksigner` (v1 scheme, min SDK 19);
- the keep-on logic behaves as specified (`tests/run_tests.sh`);
- the engine refuses an already-patched app, an app with a missing hook, and an app with an ambiguous hook;
- a static check of the tool programs against the car's own Android 4.4 framework found the classes and methods they call.
  The only gaps are in code the tools do not run: the command-line parser, a hidden-API flag class, and one raw-dump method.

## What is NOT verified

- **Nothing here has run on a head unit.** Whether `dalvikvm` runs these tools on Android 4.4 (memory, speed, the
  trimmed libraries) is unknown until the self-test runs there.
- **The UI built in code has never been drawn.** Its sizes and spacing copy the original layout, but it has not been seen on a screen.
- **Whether the car accepts the rebuilt app** is as unverified here as it was for the original method before its first install.
- It builds in a scratch folder under `/data/nemesis`. How long that takes, and how much space it needs (a few hundred MB), is unmeasured.
- Same limits as the original method: the keep-on rewrites the stored value at most three times in a row, only for writes made
  through this app, and checking Persist does not send a command to the car.

## Install

Build the package (or use the one in `dist/`):

```sh
export BAKSMALI_JAR=/path/to/baksmali.jar SMALI_JAR=/path/to/smali.jar
export D8=$HOME/Library/Android/sdk/build-tools/36.0.0/d8
export ANDROID_JAR=$HOME/Library/Android/sdk/platforms/android-36/android.jar
sh experimental/build.sh 0.1.0
```

Install over adb:

```sh
adb push experimental/dist/ev3-persist-experimental-0.1.0.zip /data/local/tmp/
adb shell /system/xbin/nemesis install /data/local/tmp/ev3-persist-experimental-0.1.0.zip
```

The install builds first (expect a few minutes), then reboots. Read the log afterwards:

```sh
adb shell cat /data/nemesis/ev3.persist.experimental.log
```

If NEMESIS reports the package as incompatible, check the `os` and `models` lines in `package/NEMESIS.data`. They are set to `*`,
and how NEMESIS treats that has not been tested.

## Uninstall and recovery

```sh
adb shell /system/xbin/nemesis uninstall ev3.persist.experimental
adb shell reboot
```

The uninstall restores the stock APK and odex from the backup, after checking them against their recorded checksums.
If a head unit will not start the app, the backup is in `/data/nemesis/backup/ev3.persist.experimental/`.

This package and the original one replace the same files. Do not install both: each refuses if the other's backup exists.

## Tests

```sh
BAKSMALI_JAR=/path/to/baksmali.jar SMALI_JAR=/path/to/smali.jar sh experimental/tests/run_tests.sh
```

Without the jars the tool tests print `SKIPPED` and the run says it is not a full pass.

Third-party code bundled in the package is listed in `THIRD_PARTY_NOTICES.md`.
