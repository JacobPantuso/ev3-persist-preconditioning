#!/system/bin/sh
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
. ./scripts/common.sh

log "preinstall $ID"
if [ ! -x "$NEMESIS" ]; then
    log "FAIL: $NEMESIS missing"
    report preinstall-fail
    exit 1
fi
if [ -d "$BACKUP_DIR" ]; then
    log "FAIL: $BACKUP_DIR exists - uninstall $ID first"
    report preinstall-fail
    exit 1
fi
if [ ! -s files/patched/HKMC_TAppEV3.apk ]; then
    log "FAIL: missing files/patched/HKMC_TAppEV3.apk"
    report preinstall-fail
    exit 1
fi
if [ "$(md5_of files/patched/HKMC_TAppEV3.apk)" != "$PATCHED_APK_MD5" ]; then
    log "FAIL: payload checksum mismatch"
    report preinstall-fail
    exit 1
fi
# the live APK and odex must be the stock pair, or something else already patched them
if [ "$(md5_of "$APP_APK")" != "$STOCK_APK_MD5" ]; then
    log "FAIL: $APP_APK is not the stock build"
    report preinstall-fail
    exit 1
fi
if [ "$(md5_of "$APP_ODEX")" != "$STOCK_ODEX_MD5" ]; then
    log "FAIL: $APP_ODEX is not the stock build"
    report preinstall-fail
    exit 1
fi
log "preinstall ok"
exit 0
