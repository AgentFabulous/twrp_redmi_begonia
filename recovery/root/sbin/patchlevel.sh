#!/sbin/sh

SCRIPTNAME="PatchLevel"
LOGFILE=/tmp/recovery.log
TEMPSYS=/s
BUILDPROP=build.prop
DEFAULTPROP=prop.default
syspath="/dev/block/bootdevice/by-name/system"
venbin="/vendor/bin"
SETDEVICE=false
SETFINGERPRINT=true

log_info() {
    echo "I:$SCRIPTNAME:$1" >> "$LOGFILE"
}

log_error() {
    echo "E:$SCRIPTNAME:$1" >> "$LOGFILE"
}

temp_mount() {
    mkdir "$1"
    if [ -d "$1" ]; then
        log_info "Temporary $2 folder created at $1."
    else
        log_error "Unable to create temporary $2 folder."
        finish_error
    fi
    mount -t ext4 -o ro "$3" "$1"
    if [ -n "$(ls -A "$1" 2>/dev/null)" ]; then
        log_info "$2 mounted at $1."
    else
        log_error "Unable to mount $2 to temporary folder."
        finish_error
    fi
}

relink() {
    log_info "Looking for $1 to update linker path..."
    if [ -f "$1" ]; then
        fname=$(basename "$1")
        target="/sbin/$fname"
        log_info "File found! Relinking $1 to $target..."
        sed 's|/system/bin/linker|///////sbin/linker|' "$1" > "$target"
        chmod 755 "$target"
    else
        log_info "File not found. Proceeding without relinking..."
    fi
}

finish() {
    umount "$TEMPSYS"
    rmdir "$TEMPSYS"
    touch /sbin/fingerprint_ready
    log_info "Script complete. Device ready for decryption."
    exit 0
}

finish_error() {
    umount "$TEMPSYS"
    rmdir "$TEMPSYS"
    log_error "Script run incomplete. Device not ready for decryption."
    exit 0
}

osver_orig=$(getprop ro.build.version.release_orig)
patchlevel_orig=$(getprop ro.build.version.security_patch_orig)
osver=$(getprop ro.build.version.release)
patchlevel=$(getprop ro.build.version.security_patch)
device=$(getprop ro.product.device)
fingerprint=$(getprop ro.build.fingerprint)
product=$(getprop ro.build.product)

log_info "Running patchlevel pre-decrypt script for TWRP..."
for file in $(find $venbin -type f); do
  relink "$file"
done

temp_mount "$TEMPSYS" "system" "$syspath"
finish
