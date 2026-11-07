#!/bin/sh
# Assemble an install zip from the package template and a built payload.
#
# usage: make_package.sh <patched.apk> <stock_apk_md5> <stock_odex_md5> <version> <out.zip>
# Run from the repository root. Writes a copy of package/ into a temporary folder, so the
# template in the repository is never changed.
set -eu
[ $# -eq 5 ] || { sed -n '2,4p' "$0" >&2; exit 1; }
PAYLOAD=$1; STOCK_APK_MD5=$2; STOCK_ODEX_MD5=$3; VERSION=$4; OUT=$5
for v in "$STOCK_APK_MD5" "$STOCK_ODEX_MD5"; do
    [ "${#v}" -eq 32 ] || { echo "md5 must be 32 characters: $v" >&2; exit 1; }
    case "$v" in *[!0-9a-f]*) echo "md5 must be lowercase hex: $v" >&2; exit 1 ;; esac
done
case "$VERSION" in *[!0-9.]*|"") echo "version must be digits and dots: $VERSION" >&2; exit 1 ;; esac
OUT_DIR=$(cd "$(dirname "$OUT")" && pwd); OUT=$OUT_DIR/$(basename "$OUT")
[ -s "$PAYLOAD" ] || { echo "payload missing: $PAYLOAD" >&2; exit 1; }
if command -v md5 >/dev/null 2>&1; then PATCHED_MD5=$(md5 -q "$PAYLOAD"); else PATCHED_MD5=$(md5sum "$PAYLOAD" | cut -d' ' -f1); fi
ROOT=$(cd "$(dirname "$0")/.." && pwd)
: "${OS:?set OS to the head unit os string (getprop ro.build.product)}"
: "${MODEL:?set MODEL to the head unit model string (for example ceev_ca)}"
[ -x "$ROOT/package/bin/lpatch" ] || { echo "package/bin/lpatch is missing or not executable; copy it in before packaging" >&2; exit 1; }
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$ROOT/package/." "$STAGE/"
mkdir -p "$STAGE/files/patched" "$STAGE/files/expect"
cp "$PAYLOAD" "$STAGE/files/patched/HKMC_TAppEV3.apk"
# files/expect/*.md5 are for people checking a build by hand; the scripts use the constants in common.sh
printf '%s\n' "$STOCK_APK_MD5" > "$STAGE/files/expect/HKMC_TAppEV3.apk.md5"
printf '%s\n' "$STOCK_ODEX_MD5" > "$STAGE/files/expect/HKMC_TAppEV3.odex.md5"
printf '%s\n' "$PATCHED_MD5" > "$STAGE/files/expect/HKMC_TAppEV3.patched.md5"
sed -i.bak -e "s/^STOCK_APK_MD5=.*/STOCK_APK_MD5=$STOCK_APK_MD5/" \
           -e "s/^STOCK_ODEX_MD5=.*/STOCK_ODEX_MD5=$STOCK_ODEX_MD5/" \
           -e "s/^PATCHED_APK_MD5=.*/PATCHED_APK_MD5=$PATCHED_MD5/" "$STAGE/scripts/common.sh"
rm -f "$STAGE/scripts/common.sh.bak"
sed -i.bak -e "s/^package-version=.*/package-version=$VERSION/" \
           -e "s/^os=.*/os=\"$OS\"/" -e "s/^models=.*/models=\"$MODEL\"/" "$STAGE/NEMESIS.data"
rm -f "$STAGE/NEMESIS.data.bak"
(cd "$STAGE" && zip -q -r "$OUT" NEMESIS.data bin scripts files)
echo "wrote $OUT (payload md5 $PATCHED_MD5)"
