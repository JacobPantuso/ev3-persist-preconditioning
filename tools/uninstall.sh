#!/bin/sh
# Remove the package over adb and restore the stock APK and odex.
set -eu
adb shell /system/xbin/nemesis uninstall ev3.persist.preconditioning
adb shell reboot
echo "uninstalled. The head unit is rebooting."
