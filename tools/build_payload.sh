#!/bin/sh
# Build the patched EV3 APK from one vehicle's own stock files.
#
# Required environment:
#   STOCK_APK        stock HKMC_TAppEV3.apk pulled from the head unit's /system/app
#   STOCK_ODEX       stock HKMC_TAppEV3.odex from the same folder
#   FRAMEWORK_DIR    the head unit's /system/framework folder (its *.odex files)
#   BAKSMALI_JAR     path to baksmali.jar (v2.x, run with -a 18)
#   SMALI_JAR        path to smali.jar (same version family as baksmali)
#   KEYSTORE         JKS keystore used to sign the payload (use your own key)
#   KEY_ALIAS        alias inside KEYSTORE
#   KEY_PASS         keystore and key password
# Optional:
#   WORK_DIR         scratch folder (default ./build)
#
# Output: $WORK_DIR/HKMC_TAppEV3.patched.apk and its md5 printed at the end.
set -eu

need() { [ -e "$1" ] || { echo "missing: $1" >&2; exit 1; }; }
for v in STOCK_APK STOCK_ODEX FRAMEWORK_DIR BAKSMALI_JAR SMALI_JAR KEYSTORE KEY_ALIAS KEY_PASS; do
    eval "val=\${$v:-}"
    [ -n "$val" ] || { echo "set $v" >&2; exit 1; }
done
for p in "$STOCK_APK" "$STOCK_ODEX" "$FRAMEWORK_DIR" "$BAKSMALI_JAR" "$SMALI_JAR" "$KEYSTORE"; do need "$p"; done
for t in java apktool jarsigner python3 zip; do
    command -v "$t" >/dev/null 2>&1 || { echo "install $t first" >&2; exit 1; }
done

HERE=$(cd "$(dirname "$0")" && pwd)
WORK_DIR=${WORK_DIR:-./build}
SAFE_HOME=${HOME:-/nonexistent}
case "$WORK_DIR" in
    ""|/|.|*..*|"$SAFE_HOME"|"$SAFE_HOME"/|/usr|/usr/*|/bin|/bin/*|/etc|/etc/*|/System|/System/*|/Library|/Library/*)
        echo "WORK_DIR=$WORK_DIR is not safe to clear; choose a subfolder of the repo" >&2; exit 1 ;;
esac
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
WORK=$(cd "$WORK_DIR" && pwd)

# 1. deodex: smali from the stock odex, resolved against this vehicle's own framework
BOOT=$(cd "$FRAMEWORK_DIR" && ls *.odex | tr '\n' ':' | sed 's/:$//')
java -jar "$BAKSMALI_JAR" x -a 18 -d "$FRAMEWORK_DIR" -b "$BOOT" -o "$WORK/smali" "$STOCK_ODEX" \
    > "$WORK/baksmali.log" 2>&1 || { echo "baksmali failed, see $WORK/baksmali.log" >&2; exit 1; }
if grep -q "skipping class" "$WORK/baksmali.log"; then
    echo "baksmali skipped classes, see $WORK/baksmali.log" >&2; exit 1
fi

# 2. smali patches: each one stops if its anchors are not found in this build
for p in patch_car.py patch_v13.py patch_v14.py patch_v15.py; do
    SMALI_ROOT="$WORK/smali" python3 "$HERE/smali/$p" || { echo "smali patch $p failed" >&2; exit 1; }
done
java -jar "$SMALI_JAR" a "$WORK/smali" -o "$WORK/classes.dex" > "$WORK/smali.log" 2>&1 \
    || { echo "smali assemble failed, see $WORK/smali.log" >&2; exit 1; }

# 3. resources: decode, patch, rebuild
apktool d -f -o "$WORK/res" "$STOCK_APK" > "$WORK/apktool-d.log" 2>&1 || { echo "apktool decode failed, see $WORK/apktool-d.log" >&2; exit 1; }
python3 "$HERE/resources/patch_resources.py" "$WORK/res" || { echo "resource patch failed (see message above)" >&2; exit 1; }
apktool b -f -o "$WORK/built.apk" "$WORK/res" > "$WORK/apktool-b.log" 2>&1 \
    || { echo "apktool build failed, see $WORK/apktool-b.log" >&2; exit 1; }

# 4. add the new dex, then sign
mkdir -p "$WORK/pkg" && cp "$WORK/built.apk" "$WORK/pkg/HKMC_TAppEV3.apk" && cp "$WORK/classes.dex" "$WORK/pkg/classes.dex"
(cd "$WORK/pkg" && zip -q -j HKMC_TAppEV3.apk classes.dex)
jarsigner -keystore "$KEYSTORE" -storepass "$KEY_PASS" -keypass "$KEY_PASS" \
    -digestalg SHA1 -sigalg SHA1withRSA "$WORK/pkg/HKMC_TAppEV3.apk" "$KEY_ALIAS" > "$WORK/sign.log" 2>&1 \
    || { echo "signing failed, see $WORK/sign.log" >&2; exit 1; }
cp "$WORK/pkg/HKMC_TAppEV3.apk" "$WORK/HKMC_TAppEV3.patched.apk"

if command -v md5 >/dev/null 2>&1; then SUM=$(md5 -q "$WORK/HKMC_TAppEV3.patched.apk"); else SUM=$(md5sum "$WORK/HKMC_TAppEV3.patched.apk" | cut -d' ' -f1); fi
echo "patched payload: $WORK/HKMC_TAppEV3.patched.apk"
echo "patched md5:     $SUM"
echo "stock md5:       $(if command -v md5 >/dev/null 2>&1; then md5 -q "$STOCK_APK"; else md5sum "$STOCK_APK" | cut -d' ' -f1; fi)"
