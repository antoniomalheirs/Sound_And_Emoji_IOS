#!/system/bin/sh
# Sound_And_Emoji_IOS — post-fs-data.sh
# Executed on every boot BEFORE modules are mounted (pre-mount stage).
#
# IMPORTANT RULES FOR THIS STAGE:
# - Do NOT use setprop (deadlocks boot). Use resetprop -n if needed.
# - Do NOT mount /system/ files here (not mounted yet).
# - Do NOT rely on module files in $MODDIR/system/ (not visible yet).
# - ONLY operate on /data/ paths that are always available.
# - Keep it FAST — this stage is BLOCKING (10s timeout).

MODDIR="${0%/*}"

# ─── Clear Downloaded Emoji Fonts (Gboard/Play Services fix) ────────
# Remove dynamically downloaded emoji fonts that override system fonts.
# These are stored in /data/ and are always accessible at this stage.
rm -rf /data/fonts/files/* 2>/dev/null

# ─── Clear Gboard Emoji Cache ───────────────────────────────────────
# Remove cached emoji packs that Gboard downloads, which override
# our custom NotoColorEmoji.ttf with stock Google emojis.
if [ -d /data/data/com.google.android.inputmethod.latin ]; then
  rm -rf /data/data/com.google.android.inputmethod.latin/files/emoji/* 2>/dev/null
  rm -rf /data/data/com.google.android.inputmethod.latin/files/superpacks/emoji* 2>/dev/null
fi
