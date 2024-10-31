SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=false

REPLACE="
"

run_install() {
  ui_print " "
  ui_print "*******************************"
  ui_print "*    Sound_And_Emoji_IOS      *"
  ui_print "*******************************"
  ui_print " "
  if [ -n "$KSU" ]; then
    ui_print "[*] Ambiente: KernelSU"
    ui_print " "
    ui_print "[*] Versão Do Modulo para KernelSU: $KSU_VER"
    ui_print "[*] Versão Do KernelSU: ${KSU_VER_CODE}" 
    sleep 0.5
    ui_print " "
	  ui_print "[*] Enable Post-FS-Data Script"
	  ui_print " "
  else
    ui_print "[*] Ambiente: Magisk"
    ui_print " "
    ui_print "[*] Versão Do Modulo para Magisk: $MAGISK_VER"
    ui_print "[*] Versão Do Magisk: ${MAGISK_VER_CODE}"
    sleep 0.5

    FONT_FILE="$MODPATH/system/fonts/NotoColorEmoji.ttf"
    SYSTEM_FONT_FILE="/system/fonts/NotoColorEmoji.ttf"
    FACEBOOK_FONT_FILE="$MODPATH/system/fonts/FacebookEmoji.ttf"

    ui_print " "
    ui_print "[*] Installing Emojis"
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

    if getprop ro.product.manufacturer | grep -qE -e "^samsung"; then
      SAMSUNG_FONT_FILE="$MODPATH/system/fonts/SamsungColorEmoji.ttf"
      mount -o bind "$FONT_FILE" "$SAMSUNG_FONT_FILE"
      chmod 644 "$SAMSUNG_FONT_FILE"

      SYSTEM_ADDITIONAL_XML="/system/etc/fonts_additional.xml"
      sed 's/<\/familyset>//g' "$SYSTEM_ADDITIONAL_XML" | cat - "$FALLBACK_XML" > "$MODPATH/system/etc/fonts_additional.xml"
      mount -o bind "$MODPATH/system/etc/fonts_additional.xml" "$SYSTEM_ADDITIONAL_XML"
    fi

    if getprop ro.product.manufacturer | grep -qE -e "^LGE"; then
      LGE_FONT_FILE="$MODPATH/system/fonts/LGNotoColorEmoji.ttf"
      mount -o bind "$FONT_FILE" "$LGE_FONT_FILE"
      chmod 644 "$LGE_FONT_FILE"
    fi

    if getprop ro.product.manufacturer | grep -qE -e "^HTC"; then
      HTC_FONT_FILE="$MODPATH/system/fonts/HTC_ColorEmoji.ttf"
      mount -o bind "$FONT_FILE" "$HTC_FONT_FILE"
      chmod 644 "$HTC_FONT_FILE"
    fi

    # Mount overlay to replace system emoji font
    mount -o bind "$FONT_FILE" "$SYSTEM_FONT_FILE"

    # Ensure correct permissions for the replacement file
    chmod 644 "$SYSTEM_FONT_FILE"

    # Mount FacebookEmoji.ttf to specified directories if Messenger or Facebook are installed
    if package_installed "com.facebook.orca"; then
      mount -o bind "$FACEBOOK_FONT_FILE" "/data/data/com.facebook.orca/app_ras_blobs/FacebookEmoji.ttf"
      chmod 644 "/data/data/com.facebook.orca/app_ras_blobs/FacebookEmoji.ttf"
    fi

    if package_installed "com.facebook.katana"; then
      mount -o bind "$FACEBOOK_FONT_FILE" "/data/data/com.facebook.katana/app_ras_blobs/FacebookEmoji.ttf"
      chmod 644 "/data/data/com.facebook.katana/app_ras_blobs/FacebookEmoji.ttf"
    fi

    #clear cache data of Gboard
    ui_print " "
    ui_print "[*] Clearing Gboard Cache"
    [ -d /data/data/com.google.android.inputmethod.latin ] && find /data -type d -path '*inputmethod.latin*/*cache*' \  -exec rm -rf {} + && am force-stop com.google.android.inputmethod.latin

    #Adding OverlayFS Support based on https://github.com/HuskyDG/magic_overlayfs 
    OVERLAY_IMAGE_EXTRA=0     # number of kb need to be added to overlay.img
    OVERLAY_IMAGE_SHRINK=true # shrink overlay.img or not?

    # Only use OverlayFS if Magisk_OverlayFS is installed
    if [ -f "/data/adb/modules/magisk_overlayfs/util_functions.sh" ] && \
      /data/adb/modules/magisk_overlayfs/overlayfs_system --test; then
      ui_print "- Add support for overlayfs"
      . /data/adb/modules/magisk_overlayfs/util_functions.sh
      support_overlayfs && rm -rf "$MODPATH"/system
    fi
    
  fi
  sleep 1
  ui_print " "
	ui_print "[*] Instalation Sucess"
  ui_print " "
}

# Function to check if a package is installed
package_installed() {
  local package="$1"
  if pm list packages | grep -q "$package"; then
    return 0
  else
    return 1
  fi
}

set_permissions() {
  set_perm_recursive  $MODPATH  0  0  0755  0644
}

run_install