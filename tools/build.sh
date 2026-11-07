#!/bin/sh
# Build the install zip and the USB descriptor from ./stock.
#
# usage: tools/build.sh <version>
# Settings come from build.env (copy build.env.example and fill it in).
set -eu
cd "$(dirname "$0")/.."
VERSION=${1:?usage: tools/build.sh <version>}
set -a
[ -f build.env ] && . ./build.env
set +a
for v in BAKSMALI_JAR SMALI_JAR KEYSTORE KEY_ALIAS KEY_PASS OS MODEL; do
    eval "val=\${$v:-}"; [ -n "$val" ] || { echo "set $v in build.env" >&2; exit 1; }
done
[ -f stock/HKMC_TAppEV3.apk ] || { echo "run tools/pull_stock.sh first" >&2; exit 1; }

export STOCK_APK=stock/HKMC_TAppEV3.apk STOCK_ODEX=stock/HKMC_TAppEV3.odex
export FRAMEWORK_DIR=stock/framework/framework WORK_DIR=build
sh tools/build_payload.sh
sh tools/verify_payload.sh build/HKMC_TAppEV3.patched.apk || { echo 'build stopped: the payload did not verify' >&2; exit 1; }
MD5=md5sum; command -v md5 >/dev/null 2>&1 && MD5="md5 -q"
STOCK_APK_MD5=$($MD5 stock/HKMC_TAppEV3.apk | cut -d' ' -f1)
STOCK_ODEX_MD5=$($MD5 stock/HKMC_TAppEV3.odex | cut -d' ' -f1)
mkdir -p out
ZIP=out/ev3-persist-$VERSION.zip
sh tools/make_package.sh build/HKMC_TAppEV3.patched.apk "$STOCK_APK_MD5" "$STOCK_ODEX_MD5" "$VERSION" "$ZIP"
printf '[nemesis]\nversion=1.0\ntype=install\npath=%s\n' "$(basename "$ZIP")" > out/NEMESIS.data
echo "ready: $ZIP  (USB descriptor: out/NEMESIS.data)"
