#!/system/bin/sh
# Sound_And_Emoji_IOS — service.sh
# Executed in late_start service mode (NON-BLOCKING).
#
# This script handles:
# 1. Force-setting ro.config.* properties via resetprop (all environments)
# 2. Replacing ALL emoji font files across ALL apps (all environments)
# 3. Disabling GMS font provider that re-downloads stock emojis
# 4. Facebook/Meta emoji lock + cache cleanup
# 5. Gboard cache cleanup
# 6. Media scanning (Magisk fallback only)

MODDIR="${0%/*}"

# ─── Logging ─────────────────────────────────────────────────────────
LOGFILE="$MODDIR/service.log"
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE" 2>/dev/null
}

log "================================================"
log "Sound_And_Emoji_IOS v1.4.5 service.sh"
log "Device: $(getprop ro.product.model)"
log "Android: $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk))"
log "================================================"

# ─── Detect environment ─────────────────────────────────────────────
IS_KSU=false
if [ -n "$KSU" ]; then
  IS_KSU=true
fi

# ─── Wait for boot ──────────────────────────────────────────────────
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done
while [ ! -d /sdcard ]; do
  sleep 2
done
log "INFO: Boot completed, service starting."

# ─── Meta / Facebook App Packages ───────────────────────────────────
META_APPS="com.facebook.katana com.facebook.orca com.facebook.lite com.facebook.mlite com.instagram.android com.instapro.android"

# ─── GMS Font Services ──────────────────────────────────────────────
GMS_FONT_PROVIDER="com.google.android.gms/com.google.android.gms.fonts.provider.FontsProvider"
GMS_FONT_UPDATER="com.google.android.gms/com.google.android.gms.fonts.update.UpdateSchedulerService"

# ─── Clear Gboard Downloaded Cache ──────────────────────────────────
log "INFO: Cleaning Gboard cache..."
rm -rf /data/data/com.google.android.inputmethod.latin/files/emoji/* 2>/dev/null
rm -rf /data/data/com.google.android.inputmethod.latin/files/superpacks/emoji* 2>/dev/null

# ─── Force Sound Properties via resetprop ────────────────────────────
log "INFO: Setting sound properties via resetprop..."

if [ -d "/system/product/media/audio/ui" ]; then
  AUDIO_BASE="/system/product/media/audio"
elif [ -d "/system/media/audio/ui" ]; then
  AUDIO_BASE="/system/media/audio"
else
  AUDIO_BASE=""
fi

resetprop ro.config.ringtone IOSDefaultRingtone.ogg
resetprop ro.config.notification_sound IOSDefaultMessageNotification.ogg
resetprop ro.config.alarm_alert IOSDefaultAlarm.ogg

if [ -n "$AUDIO_BASE" ]; then
  resetprop ro.config.lock_sound "${AUDIO_BASE}/ui/Lock.ogg"
  resetprop ro.config.unlock_sound "${AUDIO_BASE}/ui/Unlock.ogg"
  resetprop ro.config.sound_fx_key "${AUDIO_BASE}/ui/KeypressStandard.ogg"
  resetprop ro.config.sound_fx_keypress_standard "${AUDIO_BASE}/ui/KeypressStandard.ogg"
  resetprop ro.config.sound_fx_keypress_spacebar "${AUDIO_BASE}/ui/KeypressSpacebar.ogg"
  resetprop ro.config.sound_fx_keypress_delete "${AUDIO_BASE}/ui/KeypressDelete.ogg"
  resetprop ro.config.sound_fx_keypress_return "${AUDIO_BASE}/ui/KeypressReturn.ogg"
  resetprop ro.config.sound_fx_keypress_invalid "${AUDIO_BASE}/ui/KeypressInvalid.ogg"
  resetprop ro.config.camera_sound "${AUDIO_BASE}/ui/camera_click.ogg"
  resetprop ro.config.camera_focus_sound "${AUDIO_BASE}/ui/camera_focus.ogg"
  resetprop ro.config.camera_record_start "${AUDIO_BASE}/ui/VideoRecord.ogg"
  resetprop ro.config.camera_record_stop "${AUDIO_BASE}/ui/VideoStop.ogg"
  resetprop ro.config.shutter_sound "${AUDIO_BASE}/ui/camera_click.ogg"
  resetprop ro.config.low_battery_sound "${AUDIO_BASE}/ui/LowBattery.ogg"
  resetprop ro.config.charging_started_sound "${AUDIO_BASE}/ui/ChargingStarted.ogg"
  resetprop ro.config.charging_stopped_sound "${AUDIO_BASE}/ui/ChargingStopped.ogg"
  resetprop ro.config.wireless_charging_started_sound "${AUDIO_BASE}/ui/WirelessChargingStarted.ogg"
  resetprop ro.config.trusted_sound "${AUDIO_BASE}/ui/Trusted.ogg"
  resetprop ro.config.nfc_transfer_complete_sound "${AUDIO_BASE}/ui/NFCTransferComplete.ogg"
  resetprop ro.config.nfc_transfer_initiated_sound "${AUDIO_BASE}/ui/NFCTransferInitiated.ogg"
  resetprop ro.config.nfc_success_sound "${AUDIO_BASE}/ui/NFCSuccess.ogg"
  resetprop ro.config.nfc_failure_sound "${AUDIO_BASE}/ui/NFCFailure.ogg"
  resetprop ro.config.nfc_initiated_sound "${AUDIO_BASE}/ui/NFCInitiated.ogg"
fi
log "INFO: Sound properties set."

# ═════════════════════════════════════════════════════════════════════
# EMOJI FIX — AGGRESSIVE APPROACH
# ═════════════════════════════════════════════════════════════════════

EMOJI_SOURCE="$MODDIR/system/fonts/NotoColorEmoji.ttf"

# ─── 1. NUCLEAR: Find and replace ALL emoji .ttf files in ALL apps ──
replace_all_emoji_fonts() {
  log "INFO: Starting global emoji font replacement..."

  if [ ! -f "$EMOJI_SOURCE" ]; then
    log "ERROR: Source emoji font not found at $EMOJI_SOURCE"
    return
  fi

# ─── 1. Replace emoji fonts globally in /data/data (excluding Meta apps and Keyboards) ─
# We exclude Keyboards (SwiftKey, Gboard) because replacing their internal fonts can cause the keyboard to crash (flicker) when opening the emoji panel.
log "INFO: Scanning for emoji fonts in /data/data..."
EMOJI_FONTS=$(find /data/data /data/user/* -iname "*emoji*.ttf" 2>/dev/null \
  | grep -v -E "com\.facebook\.|com\.instagram\.|com\.instapro\.|com\.touchtype\.swiftkey|com\.google\.android\.inputmethod")

  if [ -z "$EMOJI_FONTS" ]; then
    log "INFO: No emoji .ttf files found in app data."
    return
  fi

  for font in $EMOJI_FONTS; do
    log "INFO: Replacing: $font"
    cp -f "$EMOJI_SOURCE" "$font" 2>/dev/null
    chmod 444 "$font" 2>/dev/null
    log "INFO: Replaced: $font"
  done

  log "INFO: Global emoji font replacement completed."
}

replace_all_emoji_fonts

# ─── 2. Lock Meta app emoji files (create if missing) ───────────────
lock_meta_emoji() {
  log "INFO: Locking Meta app emoji files..."

  for pkg in $META_APPS; do
    USERS=$(ls -d /data/data /data/user/* 2>/dev/null)
    for userpath in $USERS; do
      if [ ! -d "$userpath/$pkg" ]; then
        continue
      fi

      local target="$userpath/$pkg/app_ras_blobs/FacebookEmoji.ttf"
      mkdir -p "$userpath/$pkg/app_ras_blobs" 2>/dev/null

      local app_uid=$(stat -c "%u" "$userpath/$pkg" 2>/dev/null)
      local app_gid=$(stat -c "%g" "$userpath/$pkg" 2>/dev/null)

      if [ -n "$app_uid" ] && [ -n "$app_gid" ]; then
        chown $app_uid:$app_gid "$userpath/$pkg/app_ras_blobs" 2>/dev/null
        chmod 755 "$userpath/$pkg/app_ras_blobs" 2>/dev/null
      fi

      # We use Roboto as a dummy font. Instagram's EmojiCompat parser crashes on 30MB custom fonts.
      # By using a text font, the parser fails safely and falls back to the system iOS emojis without crashing!
      cp -f "/system/fonts/Roboto-Regular.ttf" "$target" 2>/dev/null

      if [ -n "$app_uid" ] && [ -n "$app_gid" ]; then
        chown $app_uid:$app_gid "$target" 2>/dev/null
      fi

      chmod 644 "$target" 2>/dev/null
      chcon u:object_r:system_file:s0 "$target" 2>/dev/null

      log "INFO: Replaced emoji for $pkg in $userpath"
    done
  done
}

lock_meta_emoji

# ─── 3. Clean and block Messenger font caches ────────────────────────
log "INFO: Cleaning and blocking Messenger font caches..."

MESSENGER_APPS="com.facebook.orca"
for pkg in $MESSENGER_APPS; do
  USERS=$(ls -d /data/data /data/user/* 2>/dev/null)
  for userpath in $USERS; do
    dir="$userpath/$pkg/files/fonts"
    if [ -d "$dir" ]; then
      rm -rf "$dir"/* 2>/dev/null
      log "INFO: Cleaned: $dir"
    fi
    # Block Messenger from re-downloading emoji fonts
    mkdir -p "$dir" 2>/dev/null
    chmod 000 "$dir" 2>/dev/null
    log "INFO: Blocked font downloads: $dir"
  done
done

# ─── 4. Force-stop Meta apps ────────────────────────────────────────
log "INFO: Force-stopping Meta apps..."
for app in $META_APPS; do
  am force-stop "$app" 2>/dev/null
done
sleep 2

# ─── 5. Enable GMS Font Provider (needed for fallback) ────────────────
enable_gms_fonts() {
  log "INFO: Re-enabling GMS font services to prevent fallback crashes..."
  USERS=$(ls -d /data/user/* 2>/dev/null)
  for userpath in $USERS; do
    USERID=${userpath##*/}
    pm enable --user "$USERID" "$GMS_FONT_PROVIDER" >/dev/null 2>&1
    pm enable --user "$USERID" "$GMS_FONT_UPDATER" >/dev/null 2>&1
  done
}

enable_gms_fonts

# ─── 6. Clean and Block /data/fonts ───────────────────
log "INFO: Cleaning and blocking system font caches..."
rm -rf /data/fonts/* 2>/dev/null
mkdir -p /data/fonts 2>/dev/null
chmod 000 /data/fonts 2>/dev/null

find /data -type d -path "*com.google.android.gms/files/fonts*" 2>/dev/null | while read dir; do
  rm -rf "$dir"/* 2>/dev/null
  chmod 000 "$dir" 2>/dev/null
  log "INFO: Blocked GMS font dir: $dir"
done

# ─── 7. Magisk-only: Media Scanner Fallback ─────────────────────────
if [ "$IS_KSU" = false ]; then
  sleep 8

  scan_media() {
    local base_path="$1"
    if [ ! -d "$base_path" ]; then
      return
    fi
    find "$base_path/alarms" "$base_path/notifications" "$base_path/ringtones" \
      -type f \( -name "*.ogg" -o -name "*.wav" \) 2>/dev/null | while read -r audio_file; do
      am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
        -d "file://$audio_file" >/dev/null 2>&1
    done
  }

  scan_media "$MODDIR/system/product/media/audio"
  scan_media "$MODDIR/system/media/audio"
  scan_media "/system/product/media/audio"
  scan_media "/system/media/audio"
  log "INFO: Media scan completed (Magisk fallback)."
fi

# ─── 8. Meta Emoji Watcher Daemon ─────────────────────────────────────
# Instagram Stories crash on HyperOS if FacebookEmoji.ttf is chmod 444 (read-only)
# because the app attempts to update the font and throws an unhandled permission exception.
# To prevent the crash, we use chmod 644 so the update succeeds. Then, this background
# daemon instantly restores the iOS emoji font silently.
start_emoji_watcher() {
  log "INFO: Starting Meta Emoji Watcher Daemon..."
  (
    while true; do
      for pkg in $META_APPS; do
        USERS=$(ls -d /data/data /data/user/* 2>/dev/null)
        for userpath in $USERS; do
          target="$userpath/$pkg/app_ras_blobs/FacebookEmoji.ttf"
          if [ -f "$target" ]; then
            source_size=$(stat -c "%s" "/system/fonts/Roboto-Regular.ttf" 2>/dev/null)
            target_size=$(stat -c "%s" "$target" 2>/dev/null)
            
            if [ -n "$source_size" ] && [ -n "$target_size" ] && [ "$source_size" != "$target_size" ]; then
              log "WATCHER: Detected font change in $pkg. Restoring dummy font..."
              cp -f "/system/fonts/Roboto-Regular.ttf" "$target" 2>/dev/null
              
              app_uid=$(stat -c "%u" "$userpath/$pkg" 2>/dev/null)
              app_gid=$(stat -c "%g" "$userpath/$pkg" 2>/dev/null)
              if [ -n "$app_uid" ] && [ -n "$app_gid" ]; then
                chown $app_uid:$app_gid "$target" 2>/dev/null
              fi
              
              chmod 644 "$target" 2>/dev/null
              chcon u:object_r:system_file:s0 "$target" 2>/dev/null
            fi
          fi
        done
      done
      sleep 10
    done
  ) &
}

start_emoji_watcher

log "INFO: Service completed."
log "================================================"
