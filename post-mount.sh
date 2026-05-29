#!/system/bin/sh
# Sound_And_Emoji_IOS — post-mount.sh
# Executed AFTER OverlayFS/MagicMount has mounted all module files.
#
# SUPPORTED BY: KernelSU, KernelSU Next, APatch
# NOT SUPPORTED BY: Magisk (fallback is in service.sh)

MODDIR="${0%/*}"

# ─── Variables ───────────────────────────────────────────────────────
EMOJI_SOURCE="/system/fonts/NotoColorEmoji.ttf"
EMOJI_SOURCE_MOD="$MODDIR/system/fonts/NotoColorEmoji.ttf"

# Meta app packages
META_APPS="com.facebook.katana com.facebook.orca com.facebook.lite com.facebook.mlite com.instagram.android com.instapro.android"

# ─── Determine best emoji source ────────────────────────────────────
SOURCE=""
if [ -f "$EMOJI_SOURCE" ]; then
  SOURCE="$EMOJI_SOURCE"
elif [ -f "$EMOJI_SOURCE_MOD" ]; then
  SOURCE="$EMOJI_SOURCE_MOD"
fi

if [ -z "$SOURCE" ]; then
  exit 0
fi

# ─── 1. NUCLEAR: Replace ALL *emoji*.ttf files in ALL apps ──────────
EMOJI_FONTS=$(find /data/data /data/user/* -iname "*emoji*.ttf" 2>/dev/null)
for font in $EMOJI_FONTS; do
  cp -f "$SOURCE" "$font" 2>/dev/null
  chmod 444 "$font" 2>/dev/null
done

# ─── 2. Lock Meta app emoji files (create if missing) ───────────────
for pkg in $META_APPS; do
  USERS=$(ls -d /data/data /data/user/* 2>/dev/null)
  for userpath in $USERS; do
    if [ ! -d "$userpath/$pkg" ]; then
      continue
    fi

    target="$userpath/$pkg/app_ras_blobs/FacebookEmoji.ttf"
    mkdir -p "$userpath/$pkg/app_ras_blobs" 2>/dev/null

    app_uid=$(stat -c "%u" "$userpath/$pkg" 2>/dev/null)
    app_gid=$(stat -c "%g" "$userpath/$pkg" 2>/dev/null)

    if [ -n "$app_uid" ] && [ -n "$app_gid" ]; then
      chown $app_uid:$app_gid "$userpath/$pkg/app_ras_blobs" 2>/dev/null
      chmod 755 "$userpath/$pkg/app_ras_blobs" 2>/dev/null
    fi

    cp -f "$SOURCE" "$target" 2>/dev/null

    if [ -n "$app_uid" ] && [ -n "$app_gid" ]; then
      chown $app_uid:$app_gid "$target" 2>/dev/null
    fi

    chmod 444 "$target" 2>/dev/null
    chcon u:object_r:app_data_file:s0 "$target" 2>/dev/null
  done
done

# ─── 3. Clean and block Meta font caches ──────────────
for pkg in $META_APPS; do
  USERS=$(ls -d /data/data /data/user/* 2>/dev/null)
  for userpath in $USERS; do
    dir="$userpath/$pkg/files/fonts"
    if [ -d "$dir" ]; then
      rm -rf "$dir"/* 2>/dev/null
    fi
    mkdir -p "$dir" 2>/dev/null
    chmod 000 "$dir" 2>/dev/null
  done
done

# ─── 4. Clean GMS font caches ───────────────────────────────────────
rm -rf /data/fonts 2>/dev/null
find /data -type d -path "*com.google.android.gms/files/fonts*" 2>/dev/null | while read dir; do
  rm -rf "$dir" 2>/dev/null
done
