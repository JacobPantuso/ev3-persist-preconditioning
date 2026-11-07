#!/system/bin/sh
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
. ./scripts/common.sh

log "postinstall $ID"
# before anything is changed: remove the backup we just made and stop
fail_clean() { log "FAIL: $1"; rm -rf "$BACKUP_DIR"; exit 1; }
# after something is changed: put the stock pair back; keep the backup only if that fails,
# so an uninstall can still recover
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

mkdir -p "$BACKUP_DIR" || fail_clean "cannot create $BACKUP_DIR"
cp "$APP_APK" "$BACKUP_DIR/HKMC_TAppEV3.apk" && cp "$APP_ODEX" "$BACKUP_DIR/HKMC_TAppEV3.odex" || fail_clean "backup copy failed"
if [ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.apk")" != "$STOCK_APK_MD5" ] || [ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.odex")" != "$STOCK_ODEX_MD5" ]; then
    fail_clean "backup checksum mismatch"
fi

sys_rw || fail_clean "cannot remount /system rw"
if ! put_file files/patched/HKMC_TAppEV3.apk "$APP_APK"; then
    log "FAIL: could not write $APP_APK"
    restore_stock
    report postfail-copy
    exit 1
fi
# drop the stock odex so Dalvik dexopts the new APK's classes.dex on boot
rm -f "$APP_ODEX"
if [ -e "$APP_ODEX" ]; then
    log "FAIL: $APP_ODEX could not be removed"
    restore_stock
    report postfail-odex
    exit 1
fi
sync
sys_ro
report post-install
log "installed - rebooting so Dalvik dexopts the patched APK"
exec /system/bin/reboot
log "FAIL: reboot returned"
exit 1
