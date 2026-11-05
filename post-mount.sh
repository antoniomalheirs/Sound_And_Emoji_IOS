#!/system/bin/sh
# Sound_And_Emoji_IOS — post-mount.sh
# Executed AFTER module files are mounted (pre-boot).
# RULES: Keep it simple and safe to avoid boot loops.

MODDIR="${0%/*}"

# ─── Logging ─────────────────────────────────────────────────────────
LOGFILE="$MODDIR/post-mount.log"
if [ -f "$LOGFILE" ]; then
  log_size=$(wc -c < "$LOGFILE" 2>/dev/null | tr -d ' ')
  if [ -n "$log_size" ] && [ "$log_size" -gt 102400 ]; then
    mv -f "$LOGFILE" "${LOGFILE}.old" 2>/dev/null
  fi
fi

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [POST-MOUNT] $1" >> "$LOGFILE" 2>/dev/null
}

log "================================================"
log "Sound_And_Emoji_IOS post-mount stage started"
log "================================================"

# Refresh SELinux contexts for overlay files
if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -exec chcon u:object_r:system_file:s0 {} \; 2>/dev/null
  log "Refreshed SELinux contexts on $MODDIR/system"
fi
if [ -d "$MODDIR/product" ]; then
  find "$MODDIR/product" -exec chcon u:object_r:system_file:s0 {} \; 2>/dev/null
  log "Refreshed SELinux contexts on $MODDIR/product"
fi
if [ -d "$MODDIR/system_ext" ]; then
  find "$MODDIR/system_ext" -exec chcon u:object_r:system_file:s0 {} \; 2>/dev/null
  log "Refreshed SELinux contexts on $MODDIR/system_ext"
fi

log "Sound_And_Emoji_IOS post-mount stage completed."
log "================================================"
