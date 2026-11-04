#!/system/bin/sh
# Sound_And_Emoji_IOS — post-fs-data.sh
# Executed on every boot BEFORE modules are mounted (pre-mount stage).
#
# RULES: Do NOT mount here. Keep it FAST — 10s timeout.
# Only safe /data/ cleanup.

MODDIR="${0%/*}"

# ─── Clean OTA/Mainline downloaded font updates ───────────────────────
# Remove ALL downloaded Google font updates so the system falls back to
# module overlay fonts in /system/fonts/. Then LOCK the directory to
# prevent GMS from re-downloading stock emoji fonts.
if [ -d /data/fonts/files ]; then
  chattr -i /data/fonts/files 2>/dev/null
  rm -rf /data/fonts/files/* 2>/dev/null
  chattr +i /data/fonts/files 2>/dev/null
fi
rm -f /data/system/font_config.xml 2>/dev/null

# ─── Clean GMS font caches ───────────────────────────────────────────
for gms_dir in /data/data/com.google.android.gms/files/fonts /data/user/*/com.google.android.gms/files/fonts; do
  [ -d "$gms_dir" ] && rm -rf "$gms_dir"/* 2>/dev/null
done

# ─── Clean Messenger font cache ───────────────────────────────────────
for dir in /data/data/com.facebook.orca/files/fonts /data/user/*/com.facebook.orca/files/fonts; do
  [ -d "$dir" ] && rm -rf "$dir"/* 2>/dev/null
done

# ─── Clean Gboard emoji databases and cache before apps launch ────────
# Surgical: Removes emoji databases & caches so Gboard compiles its palette
# from the newly mounted iOS font, while PRESERVING speech/voice typing models.
for gboard_dir in /data/data/com.google.android.inputmethod.latin \
                  /data/user/*/com.google.android.inputmethod.latin \
                  /data/user_de/*/com.google.android.inputmethod.latin; do
  if [ -d "$gboard_dir" ]; then
    rm -rf "$gboard_dir/databases/bundled_emoji_provider"* 2>/dev/null
    rm -rf "$gboard_dir/files/emoji"* 2>/dev/null
    rm -rf "$gboard_dir/files/superpacks/emoji"* 2>/dev/null
    rm -rf "$gboard_dir/app_textures"* 2>/dev/null
    rm -rf "$gboard_dir/files/expression"* 2>/dev/null
  fi
done

# ─── Clean Xiaomi HyperOS/MIUI theme emoji cache ─────────────────────
for theme_font in /data/system/theme/fonts /data/system/theme_magic/fonts; do
  if [ -d "$theme_font" ]; then
    rm -rf "$theme_font"/*emoji* 2>/dev/null
    rm -rf "$theme_font"/NotoColorEmoji* 2>/dev/null
    rm -rf "$theme_font"/MiuiColorEmoji* 2>/dev/null
    rm -rf "$theme_font"/MiuiEmoji* 2>/dev/null
  fi
done
