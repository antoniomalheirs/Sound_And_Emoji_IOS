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
# 6. Media scanning (all environments)

MODDIR="${0%/*}"

# ─── Logging ─────────────────────────────────────────────────────────
LOGFILE="$MODDIR/service.log"
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE" 2>/dev/null
}

log "================================================"
log "Sound_And_Emoji_IOS service.sh"
log "Device: $(getprop ro.product.model)"
log "Manufacturer: $(getprop ro.product.manufacturer)"
log "Brand: $(getprop ro.product.brand)"
log "Android: $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk))"
log "Fingerprint: $(getprop ro.build.fingerprint)"
log "OneUI: $(getprop ro.build.version.oneui 2>/dev/null)"
log "================================================"

# ─── Detect environment ─────────────────────────────────────────────
# Detection priority: filesystem presence > environment variables
# $KSU/$APATCH may exist in some KSU/APatch versions during script exec
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
log "INFO: Root manager detected: $ROOT_MGR"

# ─── Universal Audio Base Path Detection ─────────────────────────────
# Scan ALL possible audio locations to find where this device stores sounds.
# This handles Samsung, Xiaomi, OPPO, and custom ROMs that use non-standard paths.
detect_audio_base() {
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
      log "INFO: Audio path found: $candidate"
    fi
  done

  if [ -z "$AUDIO_BASE" ]; then
    log "WARN: No audio base path found on device!"
  else
    log "INFO: Primary audio base: $AUDIO_BASE"
  fi
}

detect_audio_base

# ─── GMS Font Services Definitions ──────────────────────────────────
GMS_FONT_PROVIDER="com.google.android.gms/com.google.android.gms.fonts.provider.FontsProvider"
GMS_FONT_UPDATER="com.google.android.gms/com.google.android.gms.fonts.update.UpdateSchedulerService"

# ─── Clean Dynamic System Font Caches (Safe Mode - No chmod 000) ─────
log "INFO: Cleaning dynamic system font caches..."
rm -rf /data/fonts/files/* 2>/dev/null
rm -rf /data/system/font_config.xml 2>/dev/null
if [ -d /data/fonts ]; then
  chmod 771 /data/fonts 2>/dev/null
  chown system:system /data/fonts 2>/dev/null
  chcon u:object_r:font_data_file:s0 /data/fonts 2>/dev/null
fi

# ─── Clean GMS font caches ───────────────────────────────────────────
for gms_dir in /data/data/com.google.android.gms/files/fonts /data/user/*/com.google.android.gms/files/fonts; do
  if [ -d "$gms_dir" ]; then
    rm -rf "$gms_dir"/* 2>/dev/null
  fi
done

# ─── Force Sound Properties via resetprop ────────────────────────────
set_sound_props_for_base() {
  local base="$1"
  [ -z "$base" ] && return
  log "INFO: Setting sound props for base: $base"

  local key_std="KeypressStandard.ogg"
  [ ! -f "${base}/ui/KeypressStandard.ogg" ] && [ -f "${base}/ui/keypress_standard.ogg" ] && key_std="keypress_standard.ogg"
  local key_spc="KeypressSpacebar.ogg"
  [ ! -f "${base}/ui/KeypressSpacebar.ogg" ] && [ -f "${base}/ui/keypress_spacebar.ogg" ] && key_spc="keypress_spacebar.ogg"
  local key_del="KeypressDelete.ogg"
  [ ! -f "${base}/ui/KeypressDelete.ogg" ] && [ -f "${base}/ui/keypress_delete.ogg" ] && key_del="keypress_delete.ogg"
  local key_ret="KeypressReturn.ogg"
  [ ! -f "${base}/ui/KeypressReturn.ogg" ] && [ -f "${base}/ui/keypress_return.ogg" ] && key_ret="keypress_return.ogg"
  local key_inv="KeypressInvalid.ogg"
  [ ! -f "${base}/ui/KeypressInvalid.ogg" ] && [ -f "${base}/ui/keypress_invalid.ogg" ] && key_inv="keypress_invalid.ogg"

  local lock_f="Lock.ogg"
  [ ! -f "${base}/ui/Lock.ogg" ] && [ -f "${base}/ui/lock.ogg" ] && lock_f="lock.ogg"
  local unlock_f="Unlock.ogg"
  [ ! -f "${base}/ui/Unlock.ogg" ] && [ -f "${base}/ui/unlock.ogg" ] && unlock_f="unlock.ogg"

  resetprop ro.config.ringtone IOSDefaultRingtone.ogg
  resetprop ro.config.notification_sound IOSDefaultMessageNotification.ogg
  resetprop ro.config.alarm_alert IOSDefaultAlarm.ogg

  resetprop ro.config.lock_sound "${base}/ui/${lock_f}"
  resetprop ro.config.unlock_sound "${base}/ui/${unlock_f}"
  resetprop ro.config.sound_fx_key "${base}/ui/${key_std}"
  resetprop ro.config.sound_fx_keypress_standard "${base}/ui/${key_std}"
  resetprop ro.config.sound_fx_keypress_spacebar "${base}/ui/${key_spc}"
  resetprop ro.config.sound_fx_keypress_delete "${base}/ui/${key_del}"
  resetprop ro.config.sound_fx_keypress_return "${base}/ui/${key_ret}"
  resetprop ro.config.sound_fx_keypress_invalid "${base}/ui/${key_inv}"
  resetprop ro.config.camera_sound "${base}/ui/camera_click.ogg"
  resetprop ro.config.camera_focus_sound "${base}/ui/camera_focus.ogg"
  resetprop ro.config.camera_record_start "${base}/ui/VideoRecord.ogg"
  resetprop ro.config.camera_record_stop "${base}/ui/VideoStop.ogg"
  resetprop ro.config.shutter_sound "${base}/ui/camera_click.ogg"
  resetprop ro.config.low_battery_sound "${base}/ui/LowBattery.ogg"
  resetprop ro.config.charging_started_sound "${base}/ui/ChargingStarted.ogg"
  resetprop ro.config.charging_stopped_sound "${base}/ui/ChargingStopped.ogg"
  resetprop ro.config.wireless_charging_started_sound "${base}/ui/ChargingStarted.ogg"
  resetprop ro.config.trusted_sound "${base}/ui/Trusted.ogg"
  resetprop ro.config.nfc_transfer_complete_sound "${base}/ui/NFCTransferComplete.ogg"
  resetprop ro.config.nfc_transfer_initiated_sound "${base}/ui/NFCTransferInitiated.ogg"
  resetprop ro.config.nfc_success_sound "${base}/ui/NFCSuccess.ogg"
  resetprop ro.config.nfc_failure_sound "${base}/ui/NFCFailure.ogg"
  resetprop ro.config.nfc_initiated_sound "${base}/ui/NFCInitiated.ogg"
}

if [ -n "$AUDIO_BASE" ]; then
  set_sound_props_for_base "$AUDIO_BASE"
fi
log "INFO: Sound properties set."

# ─── Wait for boot before SettingsProvider and app-level tasks ──────
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done
while [ ! -d /sdcard ]; do
  sleep 2
done
log "INFO: Boot completed, executing post-boot configuration."

# ─── Re-apply Sound Properties & SettingsProvider injection ─────────
if [ -n "$AUDIO_BASE" ]; then
  set_sound_props_for_base "$AUDIO_BASE"

  LOCK_FILE="Lock.ogg"
  [ ! -f "${AUDIO_BASE}/ui/Lock.ogg" ] && [ -f "${AUDIO_BASE}/ui/lock.ogg" ] && LOCK_FILE="lock.ogg"
  UNLOCK_FILE="Unlock.ogg"
  [ ! -f "${AUDIO_BASE}/ui/Unlock.ogg" ] && [ -f "${AUDIO_BASE}/ui/unlock.ogg" ] && UNLOCK_FILE="unlock.ogg"

  settings put global lock_sound "${AUDIO_BASE}/ui/${LOCK_FILE}" 2>/dev/null
  settings put global unlock_sound "${AUDIO_BASE}/ui/${UNLOCK_FILE}" 2>/dev/null
  settings put global trusted_sound "${AUDIO_BASE}/ui/Trusted.ogg" 2>/dev/null
  settings put global low_battery_sound "${AUDIO_BASE}/ui/LowBattery.ogg" 2>/dev/null
  settings put system lock_sound "${AUDIO_BASE}/ui/${LOCK_FILE}" 2>/dev/null
  settings put system unlock_sound "${AUDIO_BASE}/ui/${UNLOCK_FILE}" 2>/dev/null

  # Enable sound effects for system and current user
  settings put system sound_effects_enabled 1 2>/dev/null
  settings put system --user 0 sound_effects_enabled 1 2>/dev/null
  settings put system dtmf_tone 1 2>/dev/null
  settings put system --user 0 dtmf_tone 1 2>/dev/null
  log "INFO: SettingsProvider updated with lock/unlock and sound effects enabled."
fi


# ─── Diagnostic: verify module files are mounted ─────────────────────
log "INFO: ── Diagnostic: Checking if module files are visible ──"
for check_path in \
  "/system/product/media/audio/ui" \
  "/product/media/audio/ui" \
  "/system_ext/media/audio/ui" \
  "/system/media/audio/ui" \
  "/system/fonts"; do
  if [ -d "$check_path" ]; then
    file_count=$(ls "$check_path" 2>/dev/null | wc -l)
    log "INFO: $check_path exists ($file_count files)"
  fi
done

# Check specific files
for check_file in \
  "/system/fonts/NotoColorEmoji.ttf" \
  "/system/fonts/SamsungColorEmoji.ttf" \
  "/system/product/media/audio/ui/Lock.ogg" \
  "/system/media/audio/ui/Lock.ogg"; do
  if [ -f "$check_file" ]; then
    log "INFO: File exists: $check_file ($(wc -c < "$check_file" 2>/dev/null | tr -d ' ') bytes)"
  else
    log "WARN: File missing: $check_file"
  fi
done
log "INFO: ── End diagnostic ──"

# ═════════════════════════════════════════════════════════════════════
# EMOJI FIX — UNIVERSAL SCAN APPROACH
# Instead of a hardcoded list of Meta packages, we scan ALL installed
# apps for the presence of app_ras_blobs/ (Meta's emoji storage).
# This covers: Facebook, Instagram, Messenger, all Lite variants,
# AND all modded APKs (InstaPro, AeroInsta, GBInsta, InstaUltra, etc.)
# ═════════════════════════════════════════════════════════════════════

EMOJI_SOURCE="$MODDIR/system/fonts/NotoColorEmoji.ttf"

# ─── Universal: Replace FacebookEmoji.ttf with Dummy Font ──────
replace_meta_emoji_universal() {
  log "INFO: Starting universal Meta emoji scan (Dummy Font)..."
  local count=0

  for userpath in /data/data /data/user/*; do
    [ ! -d "$userpath" ] && continue

    # Find ALL app directories that contain app_ras_blobs
    for ras_dir in "$userpath"/*/app_ras_blobs; do
      [ ! -d "$ras_dir" ] && continue

      local pkg_dir="${ras_dir%/app_ras_blobs}"
      local pkg_name="${pkg_dir##*/}"
      local target="$ras_dir/FacebookEmoji.ttf"

      # SKIP Instagram entirely — its story reply emoji picker uses a
      # proprietary font renderer that crashes if FacebookEmoji.ttf is
      # replaced with ANY non-Facebook font.
      case "$pkg_name" in
        com.instagram.*|com.instapro.*|com.aeroinsta.*|com.gbinsta.*) continue ;;
      esac

      # Remove directory lock Se houver do script antigo
      if [ -d "$target" ]; then
        chmod 777 "$target" 2>/dev/null
        rm -rf "$target" 2>/dev/null
      fi
      
      # Remove arquivo imutável antigo se houver (para não quebrar atualizações da Play Store)
      if [ -e "$target" ] || [ -L "$target" ]; then
        chattr -i "$target" 2>/dev/null
        rm -f "$target" 2>/dev/null
      fi

      # Substitui com EMOJI iOS mantendo permissões legítimas do app
      if [ ! -e "$target" ]; then
        if [ -f "/system/fonts/NotoColorEmoji.ttf" ]; then
          cp -f "/system/fonts/NotoColorEmoji.ttf" "$target" 2>/dev/null
        elif [ -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" ]; then
          cp -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" "$target" 2>/dev/null
        fi
        local owner=$(stat -c '%u:%g' "$ras_dir" 2>/dev/null)
        [ -n "$owner" ] && chown "$owner" "$target" 2>/dev/null
        chmod 644 "$target" 2>/dev/null
        
        log "INFO: [UNIVERSAL] iOS Emoji aplicado em: $pkg_name"
        count=$((count + 1))
      fi
    done
  done

  # Also proactively create app_ras_blobs for known Meta apps that
  # haven't downloaded the font yet (first boot after install)
  for pkg in com.facebook.katana com.facebook.orca com.facebook.lite com.facebook.mlite; do
    for userpath in /data/data /data/user/*; do
      if [ -d "$userpath/$pkg" ] && [ ! -e "$userpath/$pkg/app_ras_blobs/FacebookEmoji.ttf" ]; then
        mkdir -p "$userpath/$pkg/app_ras_blobs" 2>/dev/null
        target="$userpath/$pkg/app_ras_blobs/FacebookEmoji.ttf"
        
        if [ -f "/system/fonts/NotoColorEmoji.ttf" ]; then
          cp -f "/system/fonts/NotoColorEmoji.ttf" "$target" 2>/dev/null
        elif [ -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" ]; then
          cp -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" "$target" 2>/dev/null
        fi
        local owner=$(stat -c '%u:%g' "$userpath/$pkg" 2>/dev/null)
        [ -n "$owner" ] && chown -R "$owner" "$userpath/$pkg/app_ras_blobs" 2>/dev/null
        chmod 644 "$target" 2>/dev/null
        
        log "INFO: [PROACTIVE] iOS Emoji aplicado em: $pkg"
        count=$((count + 1))
      fi
    done
  done

  log "INFO: Universal scan complete. Processed $count app(s)."
}

replace_meta_emoji_universal

# ─── Universal: Clean and block Messenger font caches ─────────────────
log "INFO: Cleaning Messenger-style font caches (universal)..."
for userpath in /data/data /data/user/*; do
  [ ! -d "$userpath" ] && continue
  for fonts_dir in "$userpath"/*/files/fonts; do
    [ ! -d "$fonts_dir" ] && continue
    pkg_dir="${fonts_dir%/files/fonts}"
    pkg_name="${pkg_dir##*/}"
    # Only target Facebook/Messenger apps (NOT Instagram — its story reply
    # emoji picker needs files/fonts/ resources or the keyboard crashes).
    case "$pkg_name" in
      com.facebook.*)
        rm -rf "$fonts_dir"/* 2>/dev/null
        log "INFO: Cleaned font cache: $pkg_name"
        ;;
    esac
  done
done

# ─── Universal: Force-stop all detected Meta apps ────────────────────
log "INFO: Force-stopping Meta-based apps..."
for userpath in /data/data /data/user/0; do
  [ ! -d "$userpath" ] && continue
  for ras_dir in "$userpath"/*/app_ras_blobs; do
    [ ! -d "$ras_dir" ] && continue
    pkg_dir="${ras_dir%/app_ras_blobs}"
    pkg_name="${pkg_dir##*/}"
    case "$pkg_name" in
      com.instagram.*|com.instapro.*|com.aeroinsta.*|com.gbinsta.*) continue ;;
    esac
    am force-stop "$pkg_name" 2>/dev/null
    log "INFO: Force-stopped: $pkg_name"
  done
done
sleep 2

# ─── Configure GMS Font Services ──────────────────────────────────
# Enable FontsProvider so apps can resolve system fonts without crashes.
# Permanently DISABLE UpdateSchedulerService so Google does NOT redownload stock emojis.
configure_gms_fonts() {
  log "INFO: Configuring GMS font services (disabling font updater)..."
  pm enable "$GMS_FONT_PROVIDER" >/dev/null 2>&1
  pm disable "$GMS_FONT_UPDATER" >/dev/null 2>&1
  for userpath in /data/user/*; do
    USERID=${userpath##*/}
    pm enable --user "$USERID" "$GMS_FONT_PROVIDER" >/dev/null 2>&1
    pm disable --user "$USERID" "$GMS_FONT_UPDATER" >/dev/null 2>&1
  done
  log "INFO: GMS FontsProvider enabled, UpdateSchedulerService permanently disabled."
}

configure_gms_fonts

# ─── Global Emoji Font Replacement (ALL environments) ────────────────
# Runs on ALL root managers: Magisk, KernelSU, KernelSU Next, and APatch.
# Excludes: Meta apps (handled above),
# Keyboards (SwiftKey/Gboard — replacing causes emoji panel crashes).
replace_global_emoji() {
  log "INFO: Starting global emoji font replacement in /data/data..."
  local emoji_source="/system/fonts/NotoColorEmoji.ttf"
  local emoji_source_mod="$MODDIR/system/fonts/NotoColorEmoji.ttf"
  local source=""

  if [ -f "$emoji_source" ]; then
    source="$emoji_source"
  elif [ -f "$emoji_source_mod" ]; then
    source="$emoji_source_mod"
  fi

  if [ -z "$source" ]; then
    log "WARN: No emoji source found, skipping global replacement."
    return
  fi

  local replaced=0
  EMOJI_FONTS=$(find /data/data /data/user/* -iname "*emoji*.ttf" 2>/dev/null \
    | grep -v -E "com\.facebook\.|com\.instagram\.|com\.instapro\.|com\.aeroinsta\.|com\.gbinsta\.|com\.touchtype\.swiftkey|com\.google\.android\.inputmethod")
  for font in $EMOJI_FONTS; do
    local fowner=$(stat -c '%u:%g' "$(dirname "$font")" 2>/dev/null)
    cp -f "$source" "$font" 2>/dev/null
    [ -n "$fowner" ] && chown "$fowner" "$font" 2>/dev/null
    chmod 644 "$font" 2>/dev/null
    replaced=$((replaced + 1))
  done
  log "INFO: Global emoji replacement complete. Replaced $replaced font(s)."
}

replace_global_emoji

# ─── Universal: Media Scanner ─────────────────────────────────────
# Áudios montados nas partições de sistema (/system, /product, /vendor) são
# indexados diretamente pelo MediaProvider nativo do Android em INTERNAL_CONTENT_URI.
log "INFO: Audio mounted in system paths - indexed natively by Android MediaProvider."

# ─── Universal Emoji Watcher Daemon ───────────────────────────────────
# Monitors apps with app_ras_blobs/ for emoji font changes without draining battery.
# Uses lightweight file size check (0% CPU, no 31MB flash disk reads) instead of md5sum.
WATCHER_PIDFILE="$MODDIR/watcher.pid"

start_emoji_watcher() {
  log "INFO: Starting Universal Emoji Watcher Daemon..."

  # Kill any existing watcher from a previous boot
  if [ -f "$WATCHER_PIDFILE" ]; then
    old_pid=$(cat "$WATCHER_PIDFILE" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null
      log "INFO: Killed old watcher daemon (PID $old_pid)"
    fi
    rm -f "$WATCHER_PIDFILE"
  fi

  (
    IOS_EMOJI_PATH=""
    if [ -f "/system/fonts/NotoColorEmoji.ttf" ]; then
      IOS_EMOJI_PATH="/system/fonts/NotoColorEmoji.ttf"
    elif [ -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" ]; then
      IOS_EMOJI_PATH="$MODDIR/system/fonts/NotoColorEmoji.ttf"
    fi

    if [ -z "$IOS_EMOJI_PATH" ]; then
      log "WATCHER: No iOS emoji source found. Watcher exiting."
      exit 0
    fi

    IOS_SIZE=$(wc -c < "$IOS_EMOJI_PATH" 2>/dev/null | tr -d ' ')

    while true; do
      for userpath in /data/data /data/user/*; do
        [ ! -d "$userpath" ] && continue
        for ras_dir in "$userpath"/*/app_ras_blobs; do
          [ ! -d "$ras_dir" ] && continue
          local pkg_dir="${ras_dir%/app_ras_blobs}"
          local pkg_name="${pkg_dir##*/}"

          # Skip Instagram & modded Instagram variants
          case "$pkg_name" in
            com.instagram.*|com.instapro.*|com.aeroinsta.*|com.gbinsta.*) continue ;;
          esac

          target="$ras_dir/FacebookEmoji.ttf"
          
          # Remove directory locks from old script versions
          if [ -d "$target" ]; then
             chmod 777 "$target" 2>/dev/null
             rm -rf "$target" 2>/dev/null
          fi
          
          if [ -f "$target" ]; then
            CUR_SIZE=$(wc -c < "$target" 2>/dev/null | tr -d ' ')
            if [ -n "$IOS_SIZE" ] && [ "$CUR_SIZE" != "$IOS_SIZE" ]; then
              log "WATCHER: Font replacement detected in $pkg_name. Reapplying iOS Emoji..."
              chattr -i "$target" 2>/dev/null
              rm -f "$target" 2>/dev/null
              cp -f "$IOS_EMOJI_PATH" "$target" 2>/dev/null
              local owner=$(stat -c '%u:%g' "$ras_dir" 2>/dev/null)
              [ -n "$owner" ] && chown "$owner" "$target" 2>/dev/null
              chmod 644 "$target" 2>/dev/null
            fi
          fi
        done
      done
      sleep 180
    done
  ) &
  echo $! > "$WATCHER_PIDFILE"
  log "INFO: Watcher daemon started (PID $(cat "$WATCHER_PIDFILE"))"
}

start_emoji_watcher

log "INFO: Service completed."
log "================================================"
