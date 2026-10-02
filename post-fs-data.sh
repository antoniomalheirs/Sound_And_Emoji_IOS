#!/system/bin/sh
# Sound_And_Emoji_IOS — post-fs-data.sh
# Executed on every boot BEFORE modules are mounted (pre-mount stage).
#
# RULES: Do NOT mount here. Keep it FAST — 10s timeout.
# Only safe /data/ cleanup.

MODDIR="${0%/*}"

# ─── Clean OTA/Mainline downloaded font updates ───────────────────────
# Remove downloaded Google font updates so the system falls back to module fonts
rm -rf /data/fonts/files/* 2>/dev/null
rm -rf /data/system/font_config.xml 2>/dev/null

# ─── Clean GMS font caches ───────────────────────────────────────────
for gms_dir in /data/data/com.google.android.gms/files/fonts /data/user/*/com.google.android.gms/files/fonts; do
  [ -d "$gms_dir" ] && rm -rf "$gms_dir"/* 2>/dev/null
done

# ─── Clean Messenger font cache ───────────────────────────────────────
for dir in /data/data/com.facebook.orca/files/fonts /data/user/*/com.facebook.orca/files/fonts; do
  [ -d "$dir" ] && rm -rf "$dir"/* 2>/dev/null
done
