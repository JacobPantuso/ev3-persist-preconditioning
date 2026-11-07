#!/bin/sh
# Check a built payload before it is packaged. Fails (exit 1) if any check fails.
#
# usage: tools/verify_payload.sh <patched.apk>
#
# Checks:
#   1. the signature verifies (jarsigner)
#   2. the dex contains the Persist classes and methods
#   3. the layout has the Persist row, the scroll wrapper, and the 360dp panel
#   4. the strings have the Persist title and description
set -eu
APK=${1:?usage: tools/verify_payload.sh <patched.apk>}
[ -f "$APK" ] || { echo "no such file: $APK" >&2; exit 1; }
APK=$(cd "$(dirname "$APK")" && pwd)/$(basename "$APK")
FAILS=0
ok()   { echo "ok:   $1"; }
bad()  { echo "FAIL: $1" >&2; FAILS=$((FAILS + 1)); }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1. signature
if jarsigner -verify "$APK" 2>/dev/null | grep -q "jar verified"; then
    ok "signature verifies"
else
    bad "signature does not verify"
fi

# 2. dex: the names this build must contain (they are stored as plain strings in the dex)
if (cd "$TMP" && unzip -q -o "$APK" classes.dex 2>/dev/null); then
    for name in PersistRowClick gen5wReadPersist gen5wCoercePrecond gen5wPersistSetup gen5wLoadPersistPrecond; do
        if grep -a -q "$name" "$TMP/classes.dex"; then
            ok "dex contains $name"
        else
            bad "dex is missing $name"
        fi
    done
else
    bad "no classes.dex inside the APK"
fi

# 3 and 4. resources: decode and look at the layout and strings
if apktool d -f -o "$TMP/res" "$APK" > "$TMP/apktool.log" 2>&1; then
    LAYOUT="$TMP/res/res/layout/layout_ev_settings_battery_cond_view.xml"
    if [ -f "$LAYOUT" ]; then
        grep -q "eco_evsettings_persist_precond_row" "$LAYOUT" && ok "layout has the Persist row" || bad "layout is missing the Persist row"
        grep -q "ScrollView" "$LAYOUT" && ok "layout has the scroll wrapper" || bad "layout is missing the scroll wrapper"
        grep -q 'layout_height="360.0dp"' "$LAYOUT" && ok "panel height is the stock 360dp" || bad "panel height is not 360dp"
    else
        bad "battery conditioning layout not found after decoding"
    fi
    STRINGS="$TMP/res/res/values/strings.xml"
    grep -q 'name="persist_precond_title"' "$STRINGS" && ok "Persist title string present" || bad "Persist title string missing"
    grep -q 'name="persist_precond_desc"' "$STRINGS" && ok "Persist description string present" || bad "Persist description string missing"
else
    bad "apktool could not decode the APK (see $TMP/apktool.log)"
fi

if [ "$FAILS" -eq 0 ]; then
    echo "payload verified: $APK"
else
    echo "payload FAILED verification ($FAILS check(s))" >&2
    exit 1
fi
