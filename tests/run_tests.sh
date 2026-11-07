#!/bin/sh
# Repository checks. Run from anywhere: sh tests/run_tests.sh
# These do not need the vehicle files or the Android tools; the full build is covered by
# README.md, "Steps" (the real build has to be run against your own vehicle's files).
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

# 1. shell syntax
for f in "$ROOT"/package/scripts/*.sh "$ROOT"/tools/*.sh "$ROOT"/tests/*.sh; do
    sh -n "$f" || fail "syntax: $f"
done
pass "shell scripts parse"

# 2. python compiles
python3 -m py_compile "$ROOT"/tools/smali/*.py "$ROOT"/tools/resources/*.py || fail "python compile"
find "$ROOT" -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null || true
pass "python tools compile"

# 3. the resource patch refuses a layout it does not recognise
mkdir -p "$TMP/bad/res/layout" "$TMP/bad/res/values"
printf '<?xml version="1.0" encoding="utf-8"?>\n<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android">\n</FrameLayout>\n' \
    > "$TMP/bad/res/layout/layout_ev_settings_battery_cond_view.xml"
if python3 "$ROOT/tools/resources/patch_resources.py" "$TMP/bad" > "$TMP/bad.log" 2>&1; then
    fail "patch_resources accepted an unknown layout"
fi
grep -q "anchor" "$TMP/bad.log" || fail "patch_resources did not name the missing anchor"
pass "resource patch stops on an unknown layout"

# 4. packaging writes the payload checksum, the stock checksums and the version
export OS=TESTOS MODEL=testmodel
printf 'fake payload for test\n' > "$TMP/payload.apk"
NOBIN="$TMP/nobin"; mkdir -p "$NOBIN"; cp -R "$ROOT/tools" "$ROOT/package" "$NOBIN/"; rm -rf "$NOBIN/package/bin"
STOCKA=0123456789abcdef0123456789abcdef; STOCKO=fedcba9876543210fedcba9876543210
if sh "$NOBIN/tools/make_package.sh" "$TMP/payload.apk" $STOCKA $STOCKO 9.9 "$TMP/refused.zip" > "$TMP/refused.log" 2>&1; then
    fail "packaging succeeded without package/bin/lpatch"
fi
grep -q 'lpatch' "$TMP/refused.log" || fail "packaging did not name the missing lpatch"
COPY="$TMP/copy"; mkdir -p "$COPY"; cp -R "$ROOT/tools" "$ROOT/package" "$COPY/"
mkdir -p "$COPY/package/bin"; printf '#!/bin/sh\n' > "$COPY/package/bin/lpatch"; chmod 755 "$COPY/package/bin/lpatch"
sh "$COPY/tools/make_package.sh" "$TMP/payload.apk" $STOCKA $STOCKO 9.9 "$TMP/test.zip" > /dev/null
unzip -l "$TMP/test.zip" | grep -q 'bin/lpatch' || fail "zip does not contain bin/lpatch"
unzip -p "$TMP/test.zip" scripts/common.sh | grep -q "^STOCK_APK_MD5=$STOCKA$" || fail "stock apk md5 not written"
unzip -p "$TMP/test.zip" scripts/common.sh | grep -q "^STOCK_ODEX_MD5=$STOCKO$" || fail "stock odex md5 not written"
PAYMD5=$(if command -v md5 >/dev/null 2>&1; then md5 -q "$TMP/payload.apk"; else md5sum "$TMP/payload.apk" | cut -d' ' -f1; fi)
unzip -p "$TMP/test.zip" scripts/common.sh | grep -q "^PATCHED_APK_MD5=$PAYMD5$" || fail "patched md5 not written"
unzip -p "$TMP/test.zip" NEMESIS.data | grep -q "^package-version=9.9$" || fail "version not written"
unzip -p "$TMP/test.zip" NEMESIS.data | grep -q '^os="TESTOS"$' || fail "os not written"
unzip -p "$TMP/test.zip" NEMESIS.data | grep -q '^models="testmodel"$' || fail "model not written"
pass "packaging refuses without lpatch and includes it when present"
pass "packaging writes checksums and version"

# 4b. the payload verifier refuses a file that is not a patched build
if sh "$ROOT/tools/verify_payload.sh" "$TMP/payload.apk" > "$TMP/verify.log" 2>&1; then
    fail "verify_payload accepted a file that is not an APK"
fi
pass "payload verifier refuses a non-APK"

# 5. repository hygiene: scan only the repo's own files, not the ignored build folders
PRUNE='-path "$ROOT/build" -o -path "$ROOT/stock" -o -path "$ROOT/out" -o -path "$ROOT/.git"'
BAD=$(eval "find \"$ROOT\" \( $PRUNE \) -prune -o \( -name '*.apk' -o -name '*.odex' -o -name '*.dex' -o -name '*.jar' -o -name '*.keystore' -o -name '*.jks' -o -name '*.smali' -o -name '*.zip' \) -print")
[ -z "$BAD" ] || fail "binary or key files in repo: $BAD"
NAME=$(id -un)
if grep -rIl --exclude-dir=.git --exclude-dir=build --exclude-dir=stock --exclude-dir=out --exclude=build.env --exclude=run_tests.sh -e "$NAME" -e '/Users/' "$ROOT" > "$TMP/personal.txt" 2>/dev/null; [ -s "$TMP/personal.txt" ]; then
    fail "personal path or name in: $(cat "$TMP/personal.txt")"
fi
pass "no binaries, keys, or personal details"

echo "all repository checks passed"
