#!/system/bin/sh
. ./scripts/common.sh

log "preinstall $ID"
refuse() { log "FAIL: $1 - nothing was changed"; report preinstall-fail; exit 1; }

[ -x "$NEMESIS" ] || refuse "$NEMESIS missing"
[ -x /system/bin/dalvikvm ] || refuse "/system/bin/dalvikvm missing"
[ -f "$BAK_JAR" ] && [ -f "$ASM_JAR" ] || refuse "tool jars missing from the package"
[ -f "$APP_APK" ] || refuse "$APP_APK missing"
[ -f "$APP_ODEX" ] || refuse "$APP_ODEX missing (already patched or removed?)"
[ -d "$FRAMEWORK" ] || refuse "$FRAMEWORK missing"
[ -d "$BACKUP_DIR" ] && refuse "$BACKUP_DIR exists - uninstall $ID first"
[ -d "$OTHER_BACKUP" ] && refuse "the Mac-built Persist package is installed - uninstall it first"

BCP=$(bootclasspath)
[ -n "$BCP" ] || refuse "cannot find the boot class path"

rm -rf "$WORK"
mkdir -p "$WORK/dvdata/dalvik-cache" || refuse "cannot create $WORK"

# 1. the tool must run on this head unit: both halves, on tiny sample data
tool_asm selftest "$WORK/st" || refuse "self-test (assembler half) failed; see $LOG"
tool_bak selftest "$WORK/st" || refuse "self-test (packer half) failed; see $LOG"
log "selftests passed"

# 2. the app must be an untouched stock pair: no dex in the APK, odex present
[ "$(inspect_has_dex "$APP_APK")" = 0 ] || refuse "$APP_APK already contains a dex (already patched?)"

# 3. build the patched APK in the scratch folder
log "building (this takes a few minutes)"
tool_bak deodex "$APP_ODEX" "$FRAMEWORK" "$WORK/smali" || refuse "deodex failed; see $LOG"
tool_bak patch "$WORK/smali" "$PKG/helper" || refuse "this build is not supported (patch refused); see $LOG"
tool_asm assemble "$WORK/smali" "$WORK/classes.dex" || refuse "assemble failed; see $LOG"
tool_bak pack "$APP_APK" "$WORK/classes.dex" "$STAGE_APK" || refuse "pack failed; see $LOG"
tool_bak verify "$STAGE_APK" || refuse "the built APK did not verify; see $LOG"

# 4. remember what the live files are, so the swap can check nothing changed in between
echo "$(md5_of "$APP_APK")" > "$WORK/live-apk.md5"
echo "$(md5_of "$APP_ODEX")" > "$WORK/live-odex.md5"
echo "$(md5_of "$STAGE_APK")" > "$WORK/stage.md5"
rm -rf "$WORK/smali"
log "preinstall ok: built and verified $STAGE_APK"
exit 0
