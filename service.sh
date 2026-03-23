#!/system/bin/sh
# Sound_And_Emoji_IOS — service.sh
# 
# This script runs late in the boot process (LATESTARTSERVICE).
# It's crucial for KernelSU Next / OverlayFS environments because 
# their mounts often happen AFTER the Android MediaScanner has already
# finished scanning the /system partition. 
# 
# This script forcefully tells the Android MediaStore to index our 
# newly injected ringtones, alarms, and notifications so they appear 
# in the Settings app.

MODDIR="${0%/*}"

# ─── Clear Gboard Downloaded Cache ───────────────────────────────────
# Clean specific superpacks and emoji files from Gboard data directory
rm -rf /data/data/com.google.android.inputmethod.latin/files/emoji/* 2>/dev/null
rm -rf /data/data/com.google.android.inputmethod.latin/files/superpacks/emoji* 2>/dev/null

# Wait until the system has fully booted and the MediaProvider is ready
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

# Give the MediaProvider an extra 10 seconds to settle
sleep 10

scan_media() {
    local base_path="$1"
    
    if [ ! -d "$base_path" ]; then
        return
    fi
    
    # Send a broadcast intent for EVERY .ogg file in the Media folders
    find "$base_path/alarms" "$base_path/notifications" "$base_path/ringtones" -type f -name "*.ogg" 2>/dev/null | while read -r audio_file; do
        am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$audio_file" >/dev/null 2>&1
    done
}

# Scan both possible paths where we might have placed the files
scan_media "$MODDIR/system/product/media/audio"
scan_media "$MODDIR/system/media/audio"

# Optional: If the files were mirrored heavily, tell it to scan the actual system paths too
scan_media "/system/product/media/audio"
scan_media "/system/media/audio"
