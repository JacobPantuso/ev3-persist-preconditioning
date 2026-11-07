#!/system/bin/sh
. ./scripts/common.sh

log "postinstall $ID"
BCP=$(bootclasspath)
fail_clean() { log "FAIL: $1"; rm -rf "$BACKUP_DIR"; report postinstall-fail; exit 1; }
# after /system was touched: put the stock pair back; keep the backup only if that fails
restore_stock() {
    _ok=0
    put_file "$BACKUP_DIR/HKMC_TAppEV3.apk" "$APP_APK" || _ok=1
    put_file "$BACKUP_DIR/HKMC_TAppEV3.odex" "$APP_ODEX" || _ok=1
    sys_ro
    if [ "$_ok" -eq 0 ]; then
        log "stock restored"
        rm -rf "$BACKUP_DIR"
    else
        log "WARN: stock restore incomplete - backup kept in $BACKUP_DIR for uninstall"
    fi
    return "$_ok"
}

[ -s "$STAGE_APK" ] || { log "FAIL: no staged build"; exit 1; }
[ "$(md5_of "$STAGE_APK")" = "$(cat "$WORK/stage.md5")" ] || { log "FAIL: staged build changed"; exit 1; }
[ "$(md5_of "$APP_APK")" = "$(cat "$WORK/live-apk.md5")" ] || { log "FAIL: $APP_APK changed since preinstall"; exit 1; }
[ "$(md5_of "$APP_ODEX")" = "$(cat "$WORK/live-odex.md5")" ] || { log "FAIL: $APP_ODEX changed since preinstall"; exit 1; }

# back up the stock pair and record its checksums
mkdir -p "$BACKUP_DIR" || fail_clean "cannot create $BACKUP_DIR"
cp "$APP_APK" "$BACKUP_DIR/HKMC_TAppEV3.apk" && cp "$APP_ODEX" "$BACKUP_DIR/HKMC_TAppEV3.odex" || fail_clean "backup copy failed"
[ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.apk")" = "$(cat "$WORK/live-apk.md5")" ] || fail_clean "backup apk checksum mismatch"
[ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.odex")" = "$(cat "$WORK/live-odex.md5")" ] || fail_clean "backup odex checksum mismatch"
cp "$WORK/live-apk.md5" "$BACKUP_DIR/apk.md5"
cp "$WORK/live-odex.md5" "$BACKUP_DIR/odex.md5"

sys_rw || fail_clean "cannot remount /system rw"
if ! put_file "$STAGE_APK" "$APP_APK"; then
    log "FAIL: could not write $APP_APK"
    restore_stock
    report postfail-copy
    exit 1
fi
# drop the stock odex so Dalvik optimizes the new APK's classes.dex on boot
rm -f "$APP_ODEX"
if [ -e "$APP_ODEX" ]; then
    log "FAIL: $APP_ODEX could not be removed"
    restore_stock
    report postfail-odex
    exit 1
fi
sync
sys_ro
rm -rf "$WORK/dvdata"
report post-install
log "installed - rebooting so Dalvik optimizes the rebuilt app"
exec /system/bin/reboot
log "FAIL: reboot returned"
exit 1
