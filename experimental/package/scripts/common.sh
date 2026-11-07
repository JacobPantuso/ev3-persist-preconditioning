#!/system/bin/sh
# ev3.persist.experimental - shared helpers.
#
# This package rebuilds the head unit's own EV settings app ON the head unit: it deodexes the app's odex,
# adds the Persist feature, reassembles it, signs it with a key made on the spot, and swaps it in.
# Nothing from the vendor is in this package. The build happens in a scratch folder during preinstall, so a
# failure there leaves /system untouched. Needs only toolbox commands (cp, mv, rm, cmp, chmod, chown, grep).
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib

_d=${0%/*}
[ "$_d" = "$0" ] && _d=.
PKG=$(cd "$_d/.." && pwd) || PKG=.

ID=ev3.persist.experimental
LOG=/data/nemesis/ev3.persist.experimental.log
BACKUP_DIR=/data/nemesis/backup/ev3.persist.experimental
WORK=/data/nemesis/work/ev3.persist.experimental
STAGE_APK=$WORK/HKMC_TAppEV3.patched.apk
APP_APK=/system/app/HKMC_TAppEV3.apk
APP_ODEX=/system/app/HKMC_TAppEV3.odex
FRAMEWORK=/system/framework
NEMESIS=/system/xbin/nemesis
# the Mac-built package of the same feature replaces the same files, so the two must not be mixed
OTHER_BACKUP=/data/nemesis/backup/ev3.persist.preconditioning

BAK_JAR=$PKG/tools/persist-bak.jar
ASM_JAR=$PKG/tools/persist-asm.jar

log() {
    echo "$1"
    mkdir -p /data/nemesis 2>/dev/null
    echo "$1" >> "$LOG" 2>/dev/null
    true
}

# the boot class path the head unit's own apps run with
bootclasspath() {
    if [ -n "$BOOTCLASSPATH" ]; then
        echo "$BOOTCLASSPATH"
        return
    fi
    _l=$(grep BOOTCLASSPATH /init.environ.rc 2>/dev/null)
    echo "${_l##* }"
}

# jv <jar> <class> <args...>: run a tool under dalvikvm with its own scratch dalvik-cache, output to the log
jv() {
    _jar=$1; _cls=$2; shift 2
    mkdir -p "$WORK/dvdata/dalvik-cache"
    ANDROID_ROOT=/system ANDROID_DATA="$WORK/dvdata" \
        dalvikvm -Xbootclasspath:"$BCP" -Xmx192m -classpath "$_jar" "$_cls" "$@" >> "$LOG" 2>&1
}

# the two halves of the tool (each carries its own copy of the smali library)
tool_bak() { jv "$BAK_JAR" com.gen5w.persist.tool.Tool "$@"; }
tool_asm() { jv "$ASM_JAR" com.gen5w.persist.tool.AsmTool "$@"; }

# md5_of <file>: prints the md5 only (the tool's own, since the head unit has no md5 tool)
md5_of() {
    mkdir -p "$WORK/dvdata/dalvik-cache"
    _o=$(ANDROID_ROOT=/system ANDROID_DATA="$WORK/dvdata" \
        dalvikvm -Xbootclasspath:"$BCP" -Xmx64m -classpath "$BAK_JAR" com.gen5w.persist.tool.Tool md5 "$1" 2>/dev/null) || return 1
    set -- $_o
    echo "$1"
}

# inspect_has_dex <apk>: prints 0 or 1
inspect_has_dex() {
    _o=$(ANDROID_ROOT=/system ANDROID_DATA="$WORK/dvdata" \
        dalvikvm -Xbootclasspath:"$BCP" -Xmx64m -classpath "$BAK_JAR" com.gen5w.persist.tool.Tool inspect "$1" 2>/dev/null) || return 1
    case "$_o" in
        *has_dex=0*) echo 0 ;;
        *has_dex=1*) echo 1 ;;
        *) return 1 ;;
    esac
}

# toolbox `mount -o remount` is refused on these units even as root; only NEMESIS remounts
sys_rw() { "$NEMESIS" remount rw > /dev/null 2>&1; }
sys_ro() { "$NEMESIS" remount ro > /dev/null 2>&1; true; }

# put_file <src> <dst>: copy beside the target, check, then rename over it
put_file() {
    _tmp=$2.gen5wtmp
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

# report <tag>: copy the log to the USB drive if one is writable (best effort)
report() {
    _usb=
    for _u in /storage/usb0 /storage/usb1 /storage/usb2 /mnt/media_rw/usb0 /mnt/media_rw/usb1 /mnt/media_rw/usb2; do
        [ -d "$_u" ] && [ -w "$_u" ] && { _usb=$_u; break; }
    done
    [ -n "$_usb" ] || return 0
    _r=$_usb/EV3_PERSIST_EXP_$1
    mkdir -p "$_r" 2>/dev/null || return 0
    cp "$LOG" "$_r/install.log" 2>/dev/null
    ls -la /system/app/HKMC_TAppEV3.* > "$_r/app-listing.txt" 2>&1
    return 0
}
