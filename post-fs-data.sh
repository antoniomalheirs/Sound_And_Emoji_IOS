#!/system/bin/sh
# Sound_And_Emoji_IOS — post-fs-data.sh
# Executed on every boot BEFORE modules are mounted (pre-mount stage).
#
# RULES: Do NOT use setprop. Do NOT mount. Only /data/ operations.
# Keep it FAST — this stage has a 10s timeout.

MODDIR="${0%/*}"

# ─── Nuke all font caches that could re-introduce stock emojis ──────

# 1. System downloaded font updates (Google Play System Updates)
rm -rf /data/fonts/files/* 2>/dev/null
rm -rf /data/fonts 2>/dev/null

# 2. GMS (Google Play Services) font provider cache
rm -rf /data/data/com.google.android.gms/files/fonts 2>/dev/null
find /data -type d -path "*com.google.android.gms/files/fonts*" -exec rm -rf {} + 2>/dev/null

# 3. Gboard emoji caches
if [ -d /data/data/com.google.android.inputmethod.latin ]; then
  rm -rf /data/data/com.google.android.inputmethod.latin/files/emoji/* 2>/dev/null
  rm -rf /data/data/com.google.android.inputmethod.latin/files/superpacks/emoji* 2>/dev/null
fi

# 4. Messenger font download directory (block it)
for dir in /data/data/com.facebook.orca/files/fonts /data/user/0/com.facebook.orca/files/fonts; do
  if [ -d "$dir" ]; then
    rm -rf "$dir"/* 2>/dev/null
  fi
done
