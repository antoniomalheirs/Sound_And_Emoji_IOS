#!/system/bin/sh
# Sound_And_Emoji_IOS — uninstall.sh
# Cleanup script executed when the module is removed.
# Magisk/KSU automatically removes the module directory after this runs.

MODDIR="${0%/*}"

# ─── Kill the emoji watcher daemon if running ────────────────────────
WATCHER_PIDFILE="$MODDIR/watcher.pid"
if [ -f "$WATCHER_PIDFILE" ]; then
  old_pid=$(cat "$WATCHER_PIDFILE" 2>/dev/null)
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null
  fi
  rm -f "$WATCHER_PIDFILE"
fi

# ─── Remove immutable locks from FacebookEmoji.ttf ──────────────────
# The module sets chattr +i on dummy font files. We must remove the
# immutable flag before uninstalling, or the apps will be unable to
# re-download their real emoji fonts.
for userpath in /data/data /data/user/*; do
  [ ! -d "$userpath" ] && continue
  for ras_dir in "$userpath"/*/app_ras_blobs; do
    [ ! -d "$ras_dir" ] && continue
    target="$ras_dir/FacebookEmoji.ttf"
    if [ -f "$target" ]; then
      chattr -i "$target" 2>/dev/null
      rm -f "$target" 2>/dev/null
    fi
  done
  # Restore font cache directories permissions
  for fonts_dir in "$userpath"/*/files/fonts; do
    [ ! -d "$fonts_dir" ] && continue
    chmod 755 "$fonts_dir" 2>/dev/null
  done
done

# ─── Clean up module caches and restore font permissions ─────────────
chmod 771 /data/fonts 2>/dev/null
rm -rf /data/fonts 2>/dev/null