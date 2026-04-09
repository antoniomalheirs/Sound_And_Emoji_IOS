#!/system/bin/sh
# Sound_And_Emoji_IOS — service.sh
# Executed in late_start service mode (NON-BLOCKING).
#
# This script handles:
# 1. Gboard cache cleanup (all environments)
# 2. Force-setting ro.config.* properties via resetprop (all environments)
# 3. Facebook emoji bind mounts (Magisk fallback)
# 4. Media scanning (Magisk fallback)
#
# On KernelSU/APatch, post-mount.sh and boot-completed.sh handle
# items 3 and 4 respectively.

MODDIR="${0%/*}"

# ─── Detect environment ─────────────────────────────────────────────
IS_KSU=false
if [ -n "$KSU" ]; then
  IS_KSU=true
fi

# ─── Clear Gboard Downloaded Cache (runs on all environments) ───────
rm -rf /data/data/com.google.android.inputmethod.latin/files/emoji/* 2>/dev/null
rm -rf /data/data/com.google.android.inputmethod.latin/files/superpacks/emoji* 2>/dev/null

# ─── Force Sound Properties via resetprop ────────────────────────────
# system.prop with ro.config.* is UNRELIABLE on Android 14/15/16
# because the system overwrites these properties during boot.
# We use resetprop here (late_start service) to force them AFTER
# the system has finished setting its own defaults.
#
# resetprop (without -n) persists across property resets.
# This works on both Magisk and KernelSU.

# Detect which path has our audio files
if [ -d "/system/product/media/audio/ui" ]; then
  AUDIO_BASE="/system/product/media/audio"
elif [ -d "/system/media/audio/ui" ]; then
  AUDIO_BASE="/system/media/audio"
else
  AUDIO_BASE=""
fi

# --- Default ringtone, notification, alarm ---
resetprop ro.config.ringtone IOSDefaultRingtone.ogg
resetprop ro.config.notification_sound IOSDefaultMessageNotification.ogg
resetprop ro.config.alarm_alert IOSDefaultAlarm.ogg

# --- Essential UI Sounds (absolute paths) ---
if [ -n "$AUDIO_BASE" ]; then
  resetprop ro.config.lock_sound "${AUDIO_BASE}/ui/Lock.ogg"
  resetprop ro.config.unlock_sound "${AUDIO_BASE}/ui/Unlock.ogg"
  resetprop ro.config.sound_fx_key "${AUDIO_BASE}/ui/KeypressStandard.ogg"
  resetprop ro.config.sound_fx_keypress_standard "${AUDIO_BASE}/ui/KeypressStandard.ogg"
  resetprop ro.config.sound_fx_keypress_spacebar "${AUDIO_BASE}/ui/KeypressSpacebar.ogg"
  resetprop ro.config.sound_fx_keypress_delete "${AUDIO_BASE}/ui/KeypressDelete.ogg"
  resetprop ro.config.sound_fx_keypress_return "${AUDIO_BASE}/ui/KeypressReturn.ogg"
  resetprop ro.config.sound_fx_keypress_invalid "${AUDIO_BASE}/ui/KeypressInvalid.ogg"

  # --- Camera & Recorder ---
  resetprop ro.config.camera_sound "${AUDIO_BASE}/ui/camera_click.ogg"
  resetprop ro.config.camera_focus_sound "${AUDIO_BASE}/ui/camera_focus.ogg"
  resetprop ro.config.camera_record_start "${AUDIO_BASE}/ui/VideoRecord.ogg"
  resetprop ro.config.camera_record_stop "${AUDIO_BASE}/ui/VideoStop.ogg"
  resetprop ro.config.shutter_sound "${AUDIO_BASE}/ui/camera_click.ogg"

  # --- Battery & Charging ---
  resetprop ro.config.low_battery_sound "${AUDIO_BASE}/ui/LowBattery.ogg"
  resetprop ro.config.charging_started_sound "${AUDIO_BASE}/ui/ChargingStarted.ogg"
  resetprop ro.config.charging_stopped_sound "${AUDIO_BASE}/ui/ChargingStopped.ogg"
  resetprop ro.config.wireless_charging_started_sound "${AUDIO_BASE}/ui/WirelessChargingStarted.ogg"

  # --- Security & NFC ---
  resetprop ro.config.trusted_sound "${AUDIO_BASE}/ui/Trusted.ogg"
  resetprop ro.config.nfc_transfer_complete_sound "${AUDIO_BASE}/ui/NFCTransferComplete.ogg"
  resetprop ro.config.nfc_transfer_initiated_sound "${AUDIO_BASE}/ui/NFCTransferInitiated.ogg"
  resetprop ro.config.nfc_success_sound "${AUDIO_BASE}/ui/NFCSuccess.ogg"
  resetprop ro.config.nfc_failure_sound "${AUDIO_BASE}/ui/NFCFailure.ogg"
  resetprop ro.config.nfc_initiated_sound "${AUDIO_BASE}/ui/NFCInitiated.ogg"
fi

# ─── Magisk-only Fallbacks ──────────────────────────────────────────
if [ "$IS_KSU" = false ]; then

  # ── Facebook Emoji Bind Mount (Magisk fallback) ──
  EMOJI_SOURCE="$MODDIR/system/fonts/FacebookEmoji.ttf"

  mount_facebook_emoji() {
    local pkg="$1"
    local blob_dir="/data/data/${pkg}/app_ras_blobs"

    if pm list packages 2>/dev/null | grep -q "^package:${pkg}$"; then
      if [ -d "$blob_dir" ] && [ -f "$EMOJI_SOURCE" ] && [ -f "${blob_dir}/FacebookEmoji.ttf" ]; then
        mount -o bind "$EMOJI_SOURCE" "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
        chmod 644 "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
      fi
    fi
  }

  mount_facebook_emoji "com.facebook.orca"
  mount_facebook_emoji "com.facebook.katana"

  # ── Media Scanner (Magisk fallback) ──
  until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
  done

  sleep 10

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
fi
