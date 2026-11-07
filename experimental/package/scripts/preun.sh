#!/system/bin/sh
. ./scripts/common.sh

log "preuninstall $ID"
BCP=$(bootclasspath)
mkdir -p "$WORK/dvdata/dalvik-cache" 2>/dev/null

if [ ! -s "$BACKUP_DIR/HKMC_TAppEV3.apk" ] || [ ! -s "$BACKUP_DIR/HKMC_TAppEV3.odex" ]; then
    # no backup is fine if the live APK is already an unpatched one with its odex (an earlier uninstall restored it)
    if [ -f "$APP_ODEX" ] && [ "$(inspect_has_dex "$APP_APK")" = 0 ]; then
        log "no backup and the app is already stock - nothing to restore"
        rm -rf "$WORK"
        exit 0
    fi
    log "FAIL: no backup in $BACKUP_DIR and the app is not stock"
    exit 1
fi
if [ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.apk")" != "$(cat "$BACKUP_DIR/apk.md5")" ] \
    || [ "$(md5_of "$BACKUP_DIR/HKMC_TAppEV3.odex")" != "$(cat "$BACKUP_DIR/odex.md5")" ]; then
    log "FAIL: the backup does not match its recorded checksums; nothing was changed"
    exit 1
fi
sys_rw || { log "FAIL: cannot remount /system rw"; exit 1; }
put_file "$BACKUP_DIR/HKMC_TAppEV3.apk" "$APP_APK" || { log "FAIL: restore apk"; sys_ro; exit 1; }
put_file "$BACKUP_DIR/HKMC_TAppEV3.odex" "$APP_ODEX" || { log "FAIL: restore odex"; sys_ro; exit 1; }
sys_ro
case "$BACKUP_DIR" in
    /data/nemesis/backup/ev3.persist.experimental) rm -rf "$BACKUP_DIR" ;;
    *) log "FAIL: refusing to remove $BACKUP_DIR"; exit 1 ;;
esac
rm -rf "$WORK"
sync
log "restored stock. Reboot the head unit to load it."
exit 0
