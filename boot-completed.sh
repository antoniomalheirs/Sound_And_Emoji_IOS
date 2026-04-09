#!/system/bin/sh
# Sound_And_Emoji_IOS — boot-completed.sh
# Executed AFTER sys.boot_completed=1 (system fully booted).
#
# SUPPORTED BY: KernelSU, KernelSU Next, APatch
# NOT SUPPORTED BY: Magisk (fallback is in service.sh)
#
# This script:
# 1. Force-sets ro.config.* properties via resetprop (KSU environment)
# 2. Forces Android's MediaStore to re-index custom audio files

MODDIR="${0%/*}"

# ─── Force Sound Properties via resetprop ────────────────────────────
# On KernelSU, system.prop is loaded via resetprop -n (pre-load mode)
# which might be overwritten by the system during boot. We force-set
# them again here AFTER boot is fully complete.

# Detect audio path
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

# --- Essential UI Sounds ---
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

# ─── Media Scanner ───────────────────────────────────────────────────
# Give MediaProvider a few seconds to fully settle after boot
sleep 5

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

# Scan the actual mounted system paths
scan_media "/system/product/media/audio"
scan_media "/system/media/audio"

# Also scan module paths (fallback)
scan_media "$MODDIR/system/product/media/audio"
scan_media "$MODDIR/system/media/audio"
