#!/system/bin/sh
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
. ./scripts/common.sh

log "preuninstall $ID"
if [ ! -s "$BACKUP_DIR/HKMC_TAppEV3.apk" ] || [ ! -s "$BACKUP_DIR/HKMC_TAppEV3.odex" ]; then
    # no backup is fine if the stock APK is already live (an earlier uninstall restored it)
    if [ "$(md5_of "$APP_APK")" = "$STOCK_APK_MD5" ]; then
        log "no backup and stock APK already in place - nothing to restore"
        exit 0
    fi
    log "FAIL: no backup in $BACKUP_DIR and $APP_APK is not stock"
    exit 1
fi
if [ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.apk")" != "$STOCK_APK_MD5" ] || [ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.odex")" != "$STOCK_ODEX_MD5" ]; then
    log "FAIL: backup in $BACKUP_DIR is not the stock pair; nothing was changed"
    exit 1
fi
sys_rw || { log "FAIL: cannot remount /system rw"; exit 1; }
put_file "$BACKUP_DIR/HKMC_TAppEV3.apk" "$APP_APK" || { log "FAIL: restore apk"; sys_ro; exit 1; }
put_file "$BACKUP_DIR/HKMC_TAppEV3.odex" "$APP_ODEX" || { log "FAIL: restore odex"; sys_ro; exit 1; }
sys_ro
case "$BACKUP_DIR" in
    /data/nemesis/backup/ev3.persist.preconditioning) rm -rf "$BACKUP_DIR" ;;
    *) log "FAIL: refusing to remove $BACKUP_DIR"; exit 1 ;;
esac
sync
log "restored stock"
exit 0
