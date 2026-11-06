#!/system/bin/sh
# Sound_And_Emoji_IOS — post-fs-data.sh
# Executed on every boot BEFORE modules are mounted (pre-mount stage).
#
# RULES: Do NOT mount here. Keep it FAST — 10s timeout.
# Only safe /data/ cleanup.

MODDIR="${0%/*}"

# ─── Logging ─────────────────────────────────────────────────────────
LOGFILE="$MODDIR/post-fs-data.log"
if [ -f "$LOGFILE" ]; then
  log_size=$(wc -c < "$LOGFILE" 2>/dev/null | tr -d ' ')
  if [ -n "$log_size" ] && [ "$log_size" -gt 102400 ]; then
    mv -f "$LOGFILE" "${LOGFILE}.old" 2>/dev/null
  fi
fi

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [POST-FS-DATA] $1" >> "$LOGFILE" 2>/dev/null
}

log "================================================"
log "Sound_And_Emoji_IOS post-fs-data stage started"
log "Device: $(getprop ro.product.model)"
log "================================================"

# ─── Clean OTA/Mainline downloaded font updates ───────────────────────
# Remove ALL downloaded Google font updates so the system falls back to
# module overlay fonts in /system/fonts/. Then LOCK the directory to
# prevent GMS from re-downloading stock emoji fonts.
if [ -d /data/fonts/files ]; then
  chattr -i /data/fonts/files 2>/dev/null
  fcount=$(ls -1A /data/fonts/files 2>/dev/null | wc -l)
  rm -rf /data/fonts/files/* 2>/dev/null
  chattr +i /data/fonts/files 2>/dev/null
  log "Cleaned /data/fonts/files/ ($fcount files) and locked with chattr +i"
fi
if [ -f /data/system/font_config.xml ]; then
  rm -f /data/system/font_config.xml 2>/dev/null
  log "Removed /data/system/font_config.xml"
fi

# ─── Clean GMS font caches ───────────────────────────────────────────
gms_cleaned=0
for gms_dir in /data/data/com.google.android.gms/files/fonts /data/user/*/com.google.android.gms/files/fonts; do
  if [ -d "$gms_dir" ]; then
    rm -rf "$gms_dir"/* 2>/dev/null
    gms_cleaned=$((gms_cleaned + 1))
  fi
done
[ "$gms_cleaned" -gt 0 ] && log "Cleaned $gms_cleaned GMS font cache directory(ies)"

# ─── Clean Messenger font cache ───────────────────────────────────────
orca_cleaned=0
for dir in /data/data/com.facebook.orca/files/fonts /data/user/*/com.facebook.orca/files/fonts; do
  if [ -d "$dir" ]; then
    rm -rf "$dir"/* 2>/dev/null
    orca_cleaned=$((orca_cleaned + 1))
  fi
done
[ "$orca_cleaned" -gt 0 ] && log "Cleaned $orca_cleaned Messenger font cache directory(ies)"

# ─── Clean Gboard emoji databases and cache before apps launch ────────
# Surgical: Removes emoji databases & caches so Gboard compiles its palette
# from the newly mounted iOS font, while PRESERVING speech/voice typing models.
gb_db_cleaned=0
for gboard_dir in /data/data/com.google.android.inputmethod.latin \
                  /data/user/*/com.google.android.inputmethod.latin \
                  /data/user_de/*/com.google.android.inputmethod.latin; do
  if [ -d "$gboard_dir" ]; then
    rm -rf "$gboard_dir/databases/bundled_emoji_provider"* 2>/dev/null
    rm -rf "$gboard_dir/files/emoji"* 2>/dev/null
    rm -rf "$gboard_dir/files/superpacks/emoji"* 2>/dev/null
    rm -rf "$gboard_dir/app_textures"* 2>/dev/null
    rm -rf "$gboard_dir/files/expression"* 2>/dev/null
    gb_db_cleaned=$((gb_db_cleaned + 1))
  fi
done
[ "$gb_db_cleaned" -gt 0 ] && log "Cleaned Gboard emoji caches & databases across $gb_db_cleaned user profile(s) [speech models preserved]"

# ─── Clean Xiaomi HyperOS/MIUI theme emoji cache ─────────────────────
theme_cleaned=0
for theme_font in /data/system/theme/fonts /data/system/theme_magic/fonts; do
  if [ -d "$theme_font" ]; then
    rm -rf "$theme_font"/*emoji* 2>/dev/null
    rm -rf "$theme_font"/NotoColorEmoji* 2>/dev/null
    rm -rf "$theme_font"/MiuiColorEmoji* 2>/dev/null
    rm -rf "$theme_font"/MiuiEmoji* 2>/dev/null
    theme_cleaned=$((theme_cleaned + 1))
  fi
done
[ "$theme_cleaned" -gt 0 ] && log "Cleaned Xiaomi theme emoji font cache(s)"

# ─── Extended HyperOS/MIUI Font Cache Cleanup ────────────────────────
# Only runs on Xiaomi devices. Cleans additional caches that the standard
# cleanup above doesn't cover: Theme Manager app cache, /data/fonts/config/,
# and APEX font module caches (Android 14+).
HYPEROS_VER_PFD=$(getprop ro.mi.os.version.name 2>/dev/null)
MIUI_VER_PFD=$(getprop ro.miui.ui.version.name 2>/dev/null)
if [ -n "$HYPEROS_VER_PFD" ] || [ -n "$MIUI_VER_PFD" ]; then
  log "HyperOS/MIUI detected — performing extended font cache cleanup"

  # 1. FontManagerService runtime config (forces re-read of fonts.xml on boot)
  if [ -d "/data/fonts/config" ]; then
    rm -rf /data/fonts/config/* 2>/dev/null
    log "Cleaned /data/fonts/config/"
  fi

  # 2. Theme Manager app cache (prevents stale emoji from Themes app)
  theme_mgr_cleaned=0
  for tmgr_dir in /data/data/com.android.thememanager/cache \
                  /data/data/com.android.thememanager/code_cache \
                  /data/user/*/com.android.thememanager/cache \
                  /data/user/*/com.android.thememanager/code_cache; do
    if [ -d "$tmgr_dir" ]; then
      rm -rf "$tmgr_dir"/* 2>/dev/null
      theme_mgr_cleaned=$((theme_mgr_cleaned + 1))
    fi
  done
  [ "$theme_mgr_cleaned" -gt 0 ] && log "Cleaned $theme_mgr_cleaned Theme Manager cache dir(s)"

  # 3. HyperOS theme default directory (can contain cached emoji)
  if [ -d "/data/system/theme/default" ]; then
    rm -rf /data/system/theme/default/*emoji* 2>/dev/null
    rm -rf /data/system/theme/default/*Emoji* 2>/dev/null
    log "Cleaned /data/system/theme/default/ emoji caches"
  fi

  # 4. APEX font module caches (Android 14+ Mainline font delivery)
  for apex_dir in /data/misc/apexdata/com.android.i18n; do
    if [ -d "$apex_dir" ]; then
      apex_emoji=$(find "$apex_dir" -iname "*emoji*" 2>/dev/null | wc -l)
      if [ "$apex_emoji" -gt 0 ]; then
        find "$apex_dir" -iname "*emoji*" -delete 2>/dev/null
        log "Cleaned $apex_emoji APEX emoji font(s) from $apex_dir"
      fi
    fi
  done
fi

log "Sound_And_Emoji_IOS post-fs-data stage completed."
log "================================================"
