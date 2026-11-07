#!/system/bin/sh
# ev3.persist.preconditioning - shared helpers for the install/uninstall hooks.
# Replaces /system/app/HKMC_TAppEV3.apk with a rebuilt APK (new classes.dex plus a
# Persist Preconditioning Mode checkbox) and removes its odex so Dalvik runs the APK's dex.
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib

ID=ev3.persist.preconditioning
LOG=/data/nemesis/ev3.persist.preconditioning.log
BACKUP_DIR=/data/nemesis/backup/ev3.persist.preconditioning
NEMESIS=/system/xbin/nemesis
APP_APK=/system/app/HKMC_TAppEV3.apk
APP_ODEX=/system/app/HKMC_TAppEV3.odex
STOCK_APK_MD5=c76f7e4b5a4d4bc5934b49b9e8eb5c9e
STOCK_ODEX_MD5=53e013ff8a0d36631b35e1d9eb3c7e1c
PATCHED_APK_MD5=d28a9b9a7329a980de2e925c20ec3123

log() {
    echo "$1"
    mkdir -p /data/nemesis 2>/dev/null
    echo "$1" >> "$LOG" 2>/dev/null
    true
}

sys_rw() { "$NEMESIS" remount rw > /dev/null 2>&1 || mount -o remount,rw /system > /dev/null 2>&1; }
sys_ro() { "$NEMESIS" remount ro > /dev/null 2>&1 || mount -o remount,ro /system > /dev/null 2>&1; true; }

# PKG is the package root, found from this script's own path (scripts run from the staging dir)
_d=${0%/*}
[ "$_d" = "$0" ] && _d=.
PKG=$(cd "$_d/.." && pwd) || PKG=.
LPATCH=$PKG/bin/lpatch
chmod 755 "$LPATCH" 2>/dev/null

# md5_of <file>: checksum via the bundled lpatch (the stock head unit toolbox is not relied on for this)
md5_of() {
    local _out
    _out=$("$LPATCH" md5 "$1" 2>/dev/null) || return 1
    set -- $_out
    echo "$1"
}

# put_file <src> <dst>: copy beside the target, verify, then rename over it
put_file() {
    local _tmp=$2.wcetmp
    rm -f "$_tmp" 2>/dev/null
    if ! cp "$1" "$_tmp" || ! cmp "$1" "$_tmp" > /dev/null 2>&1; then
        rm -f "$_tmp" 2>/dev/null
        return 1
    fi
    chmod 644 "$_tmp"
    chown 0.0 "$_tmp" 2>/dev/null
    mv "$_tmp" "$2" || { rm -f "$_tmp" 2>/dev/null; return 1; }
    cmp "$1" "$2" > /dev/null 2>&1
}

# report <tag>: copy the install log and a snapshot of the live files to the USB stick so it can be
# read on a PC after unplugging. Best effort: a missing or read-only USB never fails the install.
report() {
    local _usb= _d _r
    for _d in /storage/usb0 /storage/usb1 /storage/usb2 /mnt/media_rw/usb0 /mnt/media_rw/usb1 /mnt/media_rw/usb2; do
        [ -d "$_d" ] && [ -w "$_d" ] && { _usb=$_d; break; }
    done
    [ -n "$_usb" ] || { log "report: no writable USB mount"; return 0; }
    _r=$_usb/EV3_PERSIST_$1
    mkdir -p "$_r" 2>/dev/null || return 0
    cp "$LOG" "$_r/install.log" 2>/dev/null
    {
        echo "tag=$1"
        echo "date=$(date 2>/dev/null)"
        echo "app_apk_md5=$(md5_of "$APP_APK" 2>/dev/null)"
        echo "app_odex_md5=$(md5_of "$APP_ODEX" 2>/dev/null)"
        echo "stock_apk_md5=$STOCK_APK_MD5"
        echo "patched_apk_md5=$PATCHED_APK_MD5"
        echo "backup_dir=$(ls "$BACKUP_DIR" 2>/dev/null)"
    } > "$_r/state.txt" 2>&1
    ls -la /system/app/HKMC_TAppEV3.* > "$_r/app-listing.txt" 2>&1
    md5_of /system/app/HKMC_TAppEV3.apk > "$_r/live-apk-md5.txt" 2>&1
    md5_of /system/app/HKMC_TAppEV3.odex > "$_r/live-odex-md5.txt" 2>&1
    getprop ro.build.product > "$_r/build-product.txt" 2>&1
    log "report written to $_r"
    return 0
}
