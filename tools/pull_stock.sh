#!/bin/sh
# Copy this head unit's stock files into ./stock and print their checksums.
# Needs adb and one head unit connected.
set -eu
cd "$(dirname "$0")/.."
mkdir -p stock/framework
adb pull /system/app/HKMC_TAppEV3.apk stock/ > /dev/null
adb pull /system/app/HKMC_TAppEV3.odex stock/ > /dev/null
adb pull /system/framework/ stock/ > /dev/null
MD5=md5sum; command -v md5 >/dev/null 2>&1 && MD5="md5 -q"
echo "stock apk md5:  $($MD5 stock/HKMC_TAppEV3.apk)"
echo "stock odex md5: $($MD5 stock/HKMC_TAppEV3.odex)"
echo "os (for OS=):   $(adb shell getprop ro.build.product | tr -d '\r')"
echo "done. Next: copy build.env.example to build.env, fill it in, then run tools/build.sh <version>"
