#!/system/bin/sh
# Sound_And_Emoji_IOS — post-fs-data.sh
# Executed on every boot BEFORE Zygote starts.
#
# IMPORTANT: Do NOT mount /system/ files here.
# Magisk (MagicMount), KernelSU (OverlayFS/meta-overlayfs),
# KernelSU Next, and APatch all handle /system/ overlays automatically.
#
# This script is ONLY for mounts outside /system/ (e.g., /data/data/).

MODDIR="${0%/*}"

# ─── Variables ───────────────────────────────────────────────────────
FACEBOOK_FONT_FILE="$MODDIR/system/fonts/FacebookEmoji.ttf"

# ─── Clear Downloaded Emojis (Gboard fix) ────────────────────────────
# Remove any dynamically downloaded emoji fonts that override the system fonts
rm -rf /data/fonts/files/* 2>/dev/null

# ─── Helper Functions ────────────────────────────────────────────────

package_installed() {
    pm list packages 2>/dev/null | grep -q "^package:${1}$"
}

mount_facebook_emoji() {
    local pkg="$1"
    local blob_dir="/data/data/${pkg}/app_ras_blobs"

    if package_installed "$pkg" && [ -d "$blob_dir" ] && [ -f "$FACEBOOK_FONT_FILE" ]; then
        mount -o bind "$FACEBOOK_FONT_FILE" "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
        chmod 644 "${blob_dir}/FacebookEmoji.ttf" 2>/dev/null
    fi
}

# ─── Facebook / Messenger Emoji Override ─────────────────────────────
# These are in /data/data/ (NOT /system/), so they need manual mounts.

mount_facebook_emoji "com.facebook.orca"      # Messenger
mount_facebook_emoji "com.facebook.katana"     # Facebook App
