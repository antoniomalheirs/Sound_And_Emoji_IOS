#!/system/bin/sh
# Sound_And_Emoji_IOS — post-mount.sh
# Executed AFTER module files are mounted (pre-boot).
# RULES: Keep it simple and safe to avoid boot loops.

MODDIR="${0%/*}"

# Refresh SELinux contexts for overlay files
if [ -d "$MODDIR/system" ]; then
  find "$MODDIR/system" -exec chcon u:object_r:system_file:s0 {} \; 2>/dev/null
fi
