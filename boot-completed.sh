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

# ─── Logging ─────────────────────────────────────────────────────────
LOGFILE="$MODDIR/boot-completed.log"
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE" 2>/dev/null
}

log "================================================"
log "Sound_And_Emoji_IOS boot-completed.sh"
log "Device: $(getprop ro.product.model)"
log "Android: $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk))"
log "================================================"

# ─── Detect root manager ────────────────────────────────────────────
IS_KSU=false
IS_APATCH=false
IS_MAGISK=false
if [ -d "/data/adb/ksu" ] || [ -f "/data/adb/ksud" ] || [ "$KSU" = "true" ]; then
  IS_KSU=true
  ROOT_MGR="KernelSU"
elif [ -d "/data/adb/ap" ] || [ -n "$APATCH" ]; then
  IS_APATCH=true
  ROOT_MGR="APatch"
elif [ -d "/data/adb/magisk" ]; then
  IS_MAGISK=true
  ROOT_MGR="Magisk"
else
  ROOT_MGR="Unknown"
fi
log "INFO: Root manager: $ROOT_MGR"

# ─── Universal Audio Base Path Detection ─────────────────────────────
# Scan ALL possible audio locations. Covers Samsung, Xiaomi, OPPO,
# custom ROMs, and non-standard partition layouts.
AUDIO_BASE=""
AUDIO_BASES_ALL=""
for candidate in \
  /system/product/media/audio \
  /product/media/audio \
  /system_ext/media/audio \
  /vendor/media/audio \
  /odm/media/audio \
  /system/media/audio \
  /omc/media/audio \
  /system/omc/media/audio \
  /system/prism/media/audio \
  /optics/media/audio \
  /system/optics/media/audio \
  /my_product/media/audio \
  /my_region/media/audio \
  /my_stock/media/audio \
  /my_heytap/media/audio \
  /my_carrier/media/audio \
  /vgc/media/audio \
  /cust/media/audio; do
  if [ -d "$candidate/ui" ]; then
    if [ -z "$AUDIO_BASE" ]; then
      AUDIO_BASE="$candidate"
    fi
    AUDIO_BASES_ALL="$AUDIO_BASES_ALL $candidate"
  fi
done

# ─── Force Sound Properties via resetprop ────────────────────────────
# On KernelSU, system.prop is loaded via resetprop -n (pre-load mode)
# which might be overwritten by the system during boot. We force-set
# them again here AFTER boot is fully complete.

# --- Default ringtone, notification, alarm ---
resetprop ro.config.ringtone IOSDefaultRingtone.ogg
resetprop ro.config.notification_sound IOSDefaultMessageNotification.ogg
resetprop ro.config.alarm_alert IOSDefaultAlarm.ogg
log "INFO: Default sound properties set."

# --- Essential UI Sounds ---
if [ -n "$AUDIO_BASE" ]; then
  key_std="KeypressStandard.ogg"
  [ ! -f "${AUDIO_BASE}/ui/KeypressStandard.ogg" ] && [ -f "${AUDIO_BASE}/ui/keypress_standard.ogg" ] && key_std="keypress_standard.ogg"
  key_spc="KeypressSpacebar.ogg"
  [ ! -f "${AUDIO_BASE}/ui/KeypressSpacebar.ogg" ] && [ -f "${AUDIO_BASE}/ui/keypress_spacebar.ogg" ] && key_spc="keypress_spacebar.ogg"
  key_del="KeypressDelete.ogg"
  [ ! -f "${AUDIO_BASE}/ui/KeypressDelete.ogg" ] && [ -f "${AUDIO_BASE}/ui/keypress_delete.ogg" ] && key_del="keypress_delete.ogg"
  key_ret="KeypressReturn.ogg"
  [ ! -f "${AUDIO_BASE}/ui/KeypressReturn.ogg" ] && [ -f "${AUDIO_BASE}/ui/keypress_return.ogg" ] && key_ret="keypress_return.ogg"
  key_inv="KeypressInvalid.ogg"
  [ ! -f "${AUDIO_BASE}/ui/KeypressInvalid.ogg" ] && [ -f "${AUDIO_BASE}/ui/keypress_invalid.ogg" ] && key_inv="keypress_invalid.ogg"

  lock_f="Lock.ogg"
  [ ! -f "${AUDIO_BASE}/ui/Lock.ogg" ] && [ -f "${AUDIO_BASE}/ui/lock.ogg" ] && lock_f="lock.ogg"
  unlock_f="Unlock.ogg"
  [ ! -f "${AUDIO_BASE}/ui/Unlock.ogg" ] && [ -f "${AUDIO_BASE}/ui/unlock.ogg" ] && unlock_f="unlock.ogg"

  resetprop ro.config.lock_sound "${AUDIO_BASE}/ui/${lock_f}"
  resetprop ro.config.unlock_sound "${AUDIO_BASE}/ui/${unlock_f}"
  resetprop ro.config.sound_fx_key "${AUDIO_BASE}/ui/${key_std}"
  resetprop ro.config.sound_fx_keypress_standard "${AUDIO_BASE}/ui/${key_std}"
  resetprop ro.config.sound_fx_keypress_spacebar "${AUDIO_BASE}/ui/${key_spc}"
  resetprop ro.config.sound_fx_keypress_delete "${AUDIO_BASE}/ui/${key_del}"
  resetprop ro.config.sound_fx_keypress_return "${AUDIO_BASE}/ui/${key_ret}"
  resetprop ro.config.sound_fx_keypress_invalid "${AUDIO_BASE}/ui/${key_inv}"

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
  resetprop ro.config.wireless_charging_started_sound "${AUDIO_BASE}/ui/ChargingStarted.ogg"

  # --- Security & NFC ---
  resetprop ro.config.trusted_sound "${AUDIO_BASE}/ui/Trusted.ogg"
  resetprop ro.config.nfc_transfer_complete_sound "${AUDIO_BASE}/ui/NFCTransferComplete.ogg"
  resetprop ro.config.nfc_transfer_initiated_sound "${AUDIO_BASE}/ui/NFCTransferInitiated.ogg"
  resetprop ro.config.nfc_success_sound "${AUDIO_BASE}/ui/NFCSuccess.ogg"
  resetprop ro.config.nfc_failure_sound "${AUDIO_BASE}/ui/NFCFailure.ogg"

  # --- SettingsProvider injection for SystemUI & Keyguard ---
  settings put global lock_sound "${AUDIO_BASE}/ui/${lock_f}" 2>/dev/null
  settings put global unlock_sound "${AUDIO_BASE}/ui/${unlock_f}" 2>/dev/null
  settings put global trusted_sound "${AUDIO_BASE}/ui/Trusted.ogg" 2>/dev/null
  settings put global low_battery_sound "${AUDIO_BASE}/ui/LowBattery.ogg" 2>/dev/null
  settings put system lock_sound "${AUDIO_BASE}/ui/${lock_f}" 2>/dev/null
  settings put system unlock_sound "${AUDIO_BASE}/ui/${unlock_f}" 2>/dev/null

  # Enable sound effects for system and current user
  settings put system sound_effects_enabled 1 2>/dev/null
  settings put system --user 0 sound_effects_enabled 1 2>/dev/null
  settings put system dtmf_tone 1 2>/dev/null
  settings put system --user 0 dtmf_tone 1 2>/dev/null
  log "INFO: SettingsProvider updated and sound effects enabled."
fi

# ─── Media Indexing ──────────────────────────────────────────────────
# Áudios montados nas partições de sistema (/system, /product, /vendor) são
# indexados diretamente pelo MediaProvider nativo do Android em INTERNAL_CONTENT_URI.
log "INFO: Audio mounted in system paths - indexed natively by Android MediaProvider."

log "INFO: boot-completed.sh finished."
log "================================================"
