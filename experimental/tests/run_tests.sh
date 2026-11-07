#!/bin/sh
# Checks for the experimental package. Run from the repository root or from experimental/.
#
# Needs a JDK. The parts that run the tool need BAKSMALI_JAR and SMALI_JAR (the same jars the build uses);
# without them those parts print SKIPPED. They are never silently counted as passing.
#
# What this covers: the patch engine on a synthetic app (found, edited, refused), the packer and signer,
# the keep-on logic, and the contents of the package zip. What it cannot cover: running on a head unit.
set -eu
EXP=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }
skip() { echo "SKIPPED: $1"; SKIPPED=1; }
SKIPPED=0

# 1. shell syntax
for f in "$EXP"/build.sh "$EXP"/package/scripts/*.sh "$EXP"/tests/*.sh; do
    sh -n "$f" || fail "syntax: $f"
done
pass "shell scripts parse"

# 2. the keep-on logic (needs only a JDK)
mkdir -p "$TMP/state"
javac --release 8 -d "$TMP/state" "$EXP"/tests/stubs/android/util/Log.java "$EXP"/tests/stubs/android/content/*.java \
    "$EXP"/java/runtime/com/gen5w/persist/PersistState.java "$EXP"/tests/PersistStateTest.java || fail "compile PersistState test"
java -cp "$TMP/state" PersistStateTest > "$TMP/state.log" 2>&1 || { cat "$TMP/state.log"; fail "PersistState behaviour"; }
pass "keep-on logic: $(tail -1 "$TMP/state.log")"

# 3. the package zip: only our files and the converted libraries, nothing from a vehicle
ZIP=$(ls "$EXP"/dist/ev3-persist-experimental-*.zip 2>/dev/null | tail -1 || true)
[ -n "$ZIP" ] || fail "no package zip in experimental/dist"
unzip -Z1 "$ZIP" | grep -v '/$' > "$TMP/entries.txt"
for want in NEMESIS.data scripts/pre.sh scripts/post.sh scripts/preun.sh scripts/common.sh \
            tools/persist-bak.jar tools/persist-asm.jar helper/com/gen5w/persist/PersistUi.smali THIRD_PARTY_NOTICES.md; do
    grep -qx "$want" "$TMP/entries.txt" || fail "package is missing $want"
done
if grep -E '\.apk$|\.odex$|^classes\.dex$|\.keystore$|\.jks$|lpatch' "$TMP/entries.txt" > /dev/null; then
    fail "package contains a vendor-style or key file: $(grep -E '\.apk$|\.odex$|^classes\.dex$|\.keystore$|\.jks$|lpatch' "$TMP/entries.txt")"
fi
if grep -v -E '^(NEMESIS.data|THIRD_PARTY_NOTICES.md|scripts/|tools/|helper/)' "$TMP/entries.txt" > /dev/null; then
    fail "unexpected entries in the package: $(grep -v -E '^(NEMESIS.data|THIRD_PARTY_NOTICES.md|scripts/|tools/|helper/)' "$TMP/entries.txt")"
fi
# every smali file in the package belongs to our own namespace
if grep '\.smali$' "$TMP/entries.txt" | grep -v '^helper/com/gen5w/persist/' > /dev/null; then
    fail "smali outside com/gen5w/persist in the package"
fi
unzip -p "$ZIP" NEMESIS.data | grep -q '^id=ev3.persist.experimental$' || fail "package id"
SD=$(unzip -p "$ZIP" NEMESIS.data | sed -n 's/^short-desc="\(.*\)"$/\1/p')
[ "${#SD}" -le 64 ] || fail "short-desc is longer than 64 characters"
pass "package contents ($(echo "$ZIP" | sed 's#.*/##'))"

# 4 and 5 need the smali jars
if [ -z "${BAKSMALI_JAR:-}" ] || [ -z "${SMALI_JAR:-}" ] || [ ! -f "${BAKSMALI_JAR:-/x}" ] || [ ! -f "${SMALI_JAR:-/x}" ]; then
    skip "tool tests (set BAKSMALI_JAR and SMALI_JAR)"
else
    mkdir -p "$TMP/bak" "$TMP/asm"
    javac --release 8 -cp "$BAKSMALI_JAR" -d "$TMP/bak" $(ls "$EXP"/java/tool/com/gen5w/persist/tool/*.java | grep -v AsmTool) || fail "compile bak half"
    javac --release 8 -cp "$SMALI_JAR" -d "$TMP/asm" "$EXP"/java/tool/com/gen5w/persist/tool/AsmTool.java || fail "compile asm half"
    BAK="java -cp $TMP/bak:$BAKSMALI_JAR com.gen5w.persist.tool.Tool"
    ASM="java -cp $TMP/asm:$SMALI_JAR com.gen5w.persist.tool.AsmTool"

    # 4. the tool's own self-test: assemble, pack, sign, verify
    $ASM selftest "$TMP/st" > "$TMP/st-asm.log" 2>&1 || { cat "$TMP/st-asm.log"; fail "self-test (assembler half)"; }
    $BAK selftest "$TMP/st" > "$TMP/st-bak.log" 2>&1 || { cat "$TMP/st-bak.log"; fail "self-test (packer half)"; }
    grep -q "SELFTEST OK" "$TMP/st-bak.log" || fail "self-test did not report OK"
    if command -v jarsigner > /dev/null 2>&1; then
        jarsigner -verify "$TMP/st/out.apk" 2>&1 | grep -q "jar verified" || fail "jarsigner rejects the packed sample"
        pass "self-test, and the JDK's jarsigner accepts the signed sample"
    else
        pass "self-test (jarsigner not installed, so no independent signature check)"
    fi

    # 5. the patch engine on a synthetic app: it must find, edit, and assemble; and refuse an app it does not know
    FX="$TMP/fx"; mkdir -p "$FX/fake" "$TMP/helper/com/gen5w/persist"
    cat > "$FX/fake/t.smali" <<'SM'
.class public Lfake/t;
.super Ljava/lang/Object;

.method public static O(II)V
    .registers 3
    invoke-static {p0, p1}, Lfake/t;->setValue(II)V
    return-void
.end method

.method public static P(II)V
    .registers 4
    const-string v0, "logging variant"
    invoke-static {p0, p1}, Lfake/t;->setValue(II)V
    return-void
.end method

.method private static setValue(II)V
    .registers 4
    const-string v0, "Data["
    const-string v1, "] Set["
    return-void
.end method
SM
    cat > "$FX/fake/names.smali" <<'SM'
.class public Lfake/names;
.super Ljava/lang/Object;

.method public static name()Ljava/lang/String;
    .registers 1
    const-string v0, " INT.BATTERY_CONDITIONING[43]"
    return-object v0
.end method
SM
    cat > "$FX/fake/x.smali" <<'SM'
.class public Lfake/x;
.super Ljava/lang/Object;

.field private box:Landroid/widget/CheckBox;

.method public constructor <init>(Landroid/content/Context;Landroid/view/View;Landroid/os/Handler;Lcom/hkmc/media/MicomAudioManager;)V
    .registers 7
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    const/16 v0, 0x2b
    const-string v1, "unRestrictUserActions"
    return-void
.end method
SM
    cat > "$FX/fake/svc.smali" <<'SM'
.class public Lfake/svc;
.super Lcom/hkmc/app/HKMCService;

.method public onCreate()V
    .registers 2
    invoke-super {p0}, Lcom/hkmc/app/HKMCService;->onCreate()V
    const-string v0, " On Create"
    return-void
.end method
SM
    cat > "$TMP/helper/com/gen5w/persist/Fake.smali" <<'SM'
.class public Lcom/gen5w/persist/Fake;
.super Ljava/lang/Object;
SM
    cp -R "$FX" "$TMP/good"
    $BAK patch "$TMP/good" "$TMP/helper" > "$TMP/patch.log" 2>&1 || { cat "$TMP/patch.log"; fail "patch engine failed on the synthetic app"; }
    grep -q 'O\$gen5w' "$TMP/good/fake/t.smali" || fail "store write was not wrapped"
    grep -q 'PersistState;->coerce' "$TMP/good/fake/t.smali" || fail "store wrapper does not call coerce"
    grep -q 'PersistUi;->install' "$TMP/good/fake/x.smali" || fail "row constructor was not hooked"
    grep -q 'PersistState;->load' "$TMP/good/fake/svc.smali" || fail "service was not hooked"
    [ -f "$TMP/good/com/gen5w/persist/Bridge.smali" ] || fail "no Bridge generated"
    grep -q 'const/16 v0, 43' "$TMP/good/com/gen5w/persist/Bridge.smali" || fail "Bridge does not use the key found in the app"
    $ASM assemble "$TMP/good" "$TMP/good.dex" > "$TMP/asm.log" 2>&1 || { cat "$TMP/asm.log"; fail "patched synthetic app does not assemble"; }
    pass "patch engine edits the synthetic app and the result assembles"

    $BAK patch "$TMP/good" "$TMP/helper" > "$TMP/again.log" 2>&1 && fail "patch engine patched twice"
    grep -q "already patched" "$TMP/again.log" || fail "second patch did not say why it refused"
    pass "patch engine refuses an already-patched app"

    cp -R "$FX" "$TMP/nostore" && rm "$TMP/nostore/fake/t.smali"
    $BAK patch "$TMP/nostore" "$TMP/helper" > "$TMP/nostore.log" 2>&1 && fail "patch engine accepted an app with no data store"
    grep -q "REFUSED" "$TMP/nostore.log" || fail "missing hook did not give a REFUSED message"
    cp -R "$FX" "$TMP/dup" && cp "$TMP/dup/fake/svc.smali" "$TMP/dup/fake/svc2.smali" && sed -i.bak 's/Lfake\/svc;/Lfake\/svc2;/' "$TMP/dup/fake/svc2.smali" && rm -f "$TMP/dup/fake/svc2.smali.bak"
    $BAK patch "$TMP/dup" "$TMP/helper" > "$TMP/dup.log" 2>&1 && fail "patch engine accepted two settings services"
    grep -q "more than one" "$TMP/dup.log" || fail "ambiguous hook did not say 'more than one'"
    pass "patch engine refuses a missing hook and an ambiguous one"
fi

# 6. no personal details or keys in the experimental sources
NAME=$(id -un)
if grep -rIl --exclude=run_tests.sh --exclude-dir=build --exclude-dir=dist -e "$NAME" -e '/Users/' "$EXP" > "$TMP/personal.txt" 2>/dev/null; [ -s "$TMP/personal.txt" ]; then
    fail "personal path or name in: $(cat "$TMP/personal.txt")"
fi
pass "no personal details in the experimental sources"

if [ "$SKIPPED" -eq 1 ]; then
    echo "done with parts SKIPPED - not a full pass"
    exit 0
fi
echo "all experimental checks passed"
