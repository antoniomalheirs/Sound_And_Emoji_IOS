#!/system/bin/sh
# Sound_And_Emoji_IOS — post-mount.sh
# Executed AFTER OverlayFS/MagicMount has mounted all module files.
#
# This is the correct stage for operations that depend on module files
# being visible in /system/ (e.g., bind mounting custom fonts).
#
# SUPPORTED BY: KernelSU, KernelSU Next, APatch
# NOT SUPPORTED BY: Magisk (fallback is in service.sh)

MODDIR="${0%/*}"

# ─── Variables ───────────────────────────────────────────────────────
# After OverlayFS mount, our NotoColorEmoji.ttf is now visible at
# /system/fonts/. We use it as the source for Facebook emoji override.
EMOJI_SOURCE="/system/fonts/NotoColorEmoji.ttf"
EMOJI_SOURCE_MOD="$MODDIR/system/fonts/FacebookEmoji.ttf"

# ─── Helper Functions ────────────────────────────────────────────────

package_installed() {
  pm list packages 2>/dev/null | grep -q "^package:${1}$"
}

mount_facebook_emoji() {
  local pkg="$1"
  local blob_dir="/data/data/${pkg}/app_ras_blobs"

  # Only mount if the package is installed and has the blob directory
  if package_installed "$pkg" && [ -d "$blob_dir" ]; then
    # Prefer the mounted system font, fallback to module directory
    local source_file=""
    if [ -f "$EMOJI_SOURCE" ]; then
      source_file="$EMOJI_SOURCE"
    elif [ -f "$EMOJI_SOURCE_MOD" ]; then
      source_file="$EMOJI_SOURCE_MOD"
    fi

    if [ -n "$source_file" ] && [ -f "${blob_dir}/FacebookEmoji.ttf" ]; then
      mount -o bind "$source_file" "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
      # Fix permissions after bind mount
      chmod 644 "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
      chcon u:object_r:app_data_file:s0 "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
    fi
  fi
}

# ─── Facebook / Messenger Emoji Override ─────────────────────────────
# Facebook apps store their own emoji font in /data/data/ (NOT /system/)
# so they need manual bind mounts. This stage runs AFTER OverlayFS mount,
# so our font files are now accessible.

mount_facebook_emoji "com.facebook.orca"      # Messenger
mount_facebook_emoji "com.facebook.katana"    # Facebook App
