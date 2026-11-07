#!/bin/sh
# Install the zip on the head unit over adb (NEMESIS CLI).
# usage: tools/install.sh <zip>
set -eu
ZIP=${1:?usage: tools/install.sh <zip>}
NAME=$(basename "$ZIP")
adb push "$ZIP" /data/local/tmp/ > /dev/null
adb shell /system/xbin/nemesis install /data/local/tmp/"$NAME"
echo "install sent. The head unit reboots; check with: adb shell cat /data/nemesis/ev3.persist.preconditioning.log"
