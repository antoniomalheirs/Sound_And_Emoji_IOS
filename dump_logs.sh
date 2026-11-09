#!/system/bin/sh
# Sound_And_Emoji_IOS — dump_logs.sh
# Diagnostic Tool for GitHub Issues troubleshooting.
# Run anytime via root: su -c sh /data/adb/modules/Sound_And_Emoji_IOS/dump_logs.sh

MODDIR="${0%/*}"
[ -z "$MODDIR" ] || [ "$MODDIR" = "." ] && MODDIR="/data/adb/modules/Sound_And_Emoji_IOS"

REPORT_FILE="$MODDIR/diagnostic_report.log"
SD_REPORT="/sdcard/Download/Sound_And_Emoji_IOS_diagnostic.log"
SD_FALLBACK="/sdcard/Sound_And_Emoji_IOS_diagnostic.log"

echo "================================================================================"
echo "          Sound_And_Emoji_IOS — Diagnostic Collector"
echo "================================================================================"
echo "[*] Collecting device configuration, partitions, overlays and stage logs..."

# Trigger report generation directly from service logic or standalone
MOD_VER=$(grep '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)
MOD_VER_CODE=$(grep '^versionCode=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)
ROOT_MGR="Unknown"
if [ -d "/data/adb/ksu" ] || [ -f "/data/adb/ksud" ]; then
  ROOT_MGR="KernelSU"
elif [ -d "/data/adb/ap" ]; then
  ROOT_MGR="APatch"
elif [ -d "/data/adb/magisk" ]; then
  ROOT_MGR="Magisk"
fi

{
  echo "================================================================================"
  echo "       SOUND_AND_EMOJI_IOS — DIAGNOSTIC BUNDLE (ON-DEMAND)"
  echo "       Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "       Module Version: ${MOD_VER} (${MOD_VER_CODE})"
  echo "       Issue Tracker: https://github.com/antoniomalheirs/Sound_And_Emoji_IOS/issues"
  echo "================================================================================"
  echo ""
  echo "─── [1. EXECUTIVE HEALTH SUMMARY] ──────────────────────────────────────────"
  echo "Device Model      : $(getprop ro.product.model 2>/dev/null)"
  echo "Manufacturer      : $(getprop ro.product.manufacturer 2>/dev/null)"
  echo "Brand             : $(getprop ro.product.brand 2>/dev/null)"
  echo "Android OS        : $(getprop ro.build.version.release 2>/dev/null) (API $(getprop ro.build.version.sdk 2>/dev/null))"
  echo "Security Patch    : $(getprop ro.build.version.security_patch 2>/dev/null)"
  echo "Fingerprint       : $(getprop ro.build.fingerprint 2>/dev/null)"
  echo "ROM Skin          : MIUI=$(getprop ro.miui.ui.version.name 2>/dev/null) | HyperOS=$(getprop ro.mi.os.version.name 2>/dev/null) | OneUI=$(getprop ro.build.version.oneui 2>/dev/null)"
  echo "Root Manager      : $ROOT_MGR"

  meta_name="None detected"
  for mdir in /data/adb/modules/*/; do
    if [ -f "${mdir}module.prop" ] && [ ! -f "${mdir}disable" ]; then
      is_meta=false
      case "$(basename "$mdir")" in
        meta-*|*metamount*|*NanoMount*|*Mountify*|*overlayfs*) is_meta=true ;;
      esac
      if grep -q "metamodule=1" "${mdir}module.prop" 2>/dev/null; then
        is_meta=true
      fi
      if [ "$is_meta" = true ]; then
        m_pname=$(grep "^name=" "${mdir}module.prop" 2>/dev/null | cut -d= -f2)
        m_ver=$(grep "^version=" "${mdir}module.prop" 2>/dev/null | cut -d= -f2)
        meta_name="${m_pname:-$(basename "$mdir")} v${m_ver}"
        break
      fi
    fi
  done
  echo "Active Metamodule : $meta_name"

  mod_ios_size=""
  [ -f "$MODDIR/system/fonts/NotoColorEmoji.ttf" ] && mod_ios_size=$(wc -c < "$MODDIR/system/fonts/NotoColorEmoji.ttf" 2>/dev/null | tr -d ' ')

  sys_emoji_health="[FAIL] Not present"
  if [ -f "/system/fonts/NotoColorEmoji.ttf" ]; then
    se_size=$(wc -c < "/system/fonts/NotoColorEmoji.ttf" 2>/dev/null | tr -d ' ')
    [ "$se_size" = "$mod_ios_size" ] && sys_emoji_health="[PASS] Matches iOS font ($se_size bytes)" || sys_emoji_health="[WARN] Stock size ($se_size bytes vs expected $mod_ios_size)"
  fi

  prod_emoji_health="[N/A] Partition absent"
  if [ -d "/product/fonts" ]; then
    pe_check="/product/fonts/MiuiColorEmoji.ttf"
    [ ! -f "$pe_check" ] && pe_check="/product/fonts/NotoColorEmoji.ttf"
    if [ -f "$pe_check" ]; then
      pe_size=$(wc -c < "$pe_check" 2>/dev/null | tr -d ' ')
      [ "$pe_size" = "$mod_ios_size" ] && prod_emoji_health="[PASS] Matches iOS font ($pe_size bytes)" || prod_emoji_health="[WARN] Stock size ($pe_size bytes vs expected $mod_ios_size)"
    else
      prod_emoji_health="[INFO] No emoji font file in /product/fonts"
    fi
  fi
  echo "System Emoji (/system)  : $sys_emoji_health"
  echo "Product Emoji (/product): $prod_emoji_health"

  echo ""
  echo "─── [2. PARTITION ARCHITECTURE & SYMLINKS] ───────────────────────────────"
  for p in /system /product /system_ext /vendor /odm /oem; do
    if [ -L "$p" ]; then
      echo "$p → SYMLINK to $(readlink -f "$p" 2>/dev/null)"
    elif [ -d "$p" ]; then
      echo "$p → REAL DIRECTORY / PARTITION"
    else
      echo "$p → NOT PRESENT"
    fi
  done
  echo ""
  echo "─── [3. OVERLAYFS & MOUNT SUBSYSTEM] ─────────────────────────────────────"
  mount 2>/dev/null | grep -E "overlay|modules|Sound_And_Emoji" || echo "No direct overlay/module mounts found via grep."
  echo ""
  echo "─── [4. FONT XML CONFIGURATIONS] ─────────────────────────────────────────"
  for x in /system/etc/fonts.xml /system/etc/font_fallback.xml /product/etc/fonts_customization.xml /system_ext/etc/fonts_customization.xml; do
    if [ -f "$x" ]; then
      echo "FILE: $x ($(wc -c < "$x" 2>/dev/null | tr -d ' ') bytes)"
      grep -in "emoji\|MiuiColor\|und-Zsye\|Zsye\|NotoColor" "$x" 2>/dev/null | head -15 | while read -r mline; do
        echo "   $mline"
      done
    fi
  done
  echo ""
  echo "─── [5. FONT ASSET SIZE COMPARISON AUDIT] ─────────────────────────────────"
  echo "Reference iOS font in module: $mod_ios_size bytes"
  for f in \
    /system/fonts/NotoColorEmoji.ttf \
    /system/fonts/NotoColorEmojiFlags.ttf \
    /system/fonts/MiuiColorEmoji.ttf \
    /system/fonts/MiuiEmoji.ttf \
    /system/fonts/SamsungColorEmoji.ttf \
    /product/fonts/NotoColorEmoji.ttf \
    /product/fonts/MiuiColorEmoji.ttf \
    /product/fonts/MiuiEmoji.ttf \
    /system_ext/fonts/NotoColorEmoji.ttf \
    /system_ext/fonts/MiuiColorEmoji.ttf; do
    if [ -f "$f" ]; then
      fs=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
      if [ "$fs" = "$mod_ios_size" ]; then
        echo "  [MATCH] $f ($fs bytes)"
      else
        echo "  [DIFF ] $f ($fs bytes)"
      fi
    fi
  done
  echo ""
  echo "─── [5b. HYPEROS / CANOE COMPATIBILITY STATUS] ─────────────────────────────"
  echo "MIUI Version    : $(getprop ro.miui.ui.version.name 2>/dev/null || echo 'N/A')"
  echo "HyperOS Version : $(getprop ro.mi.os.version.name 2>/dev/null || echo 'N/A')"
  echo "Verified Boot   : $(getprop ro.boot.verifiedbootstate 2>/dev/null || echo 'unknown')"
  echo "Flash Locked    : $(getprop ro.boot.flash.locked 2>/dev/null || echo 'unknown')"

  # MiFontOverlay check (HyperOS/MIUI only)
  _miui=$(getprop ro.miui.ui.version.name 2>/dev/null)
  _hyperos=$(getprop ro.mi.os.version.name 2>/dev/null)
  if [ -n "$_miui" ] || [ -n "$_hyperos" ]; then
    mifont_status="NOT FOUND (⚠ emojis may not work on HyperOS without DisableMiFontOverlay)"
    if [ -d "/data/adb/modules/DisableMiFontOverlay" ] && [ ! -f "/data/adb/modules/DisableMiFontOverlay/disable" ]; then
      mifont_status="INSTALLED & ACTIVE ✅"
    else
      for _mfd in /data/adb/modules/*/; do
        if [ -f "${_mfd}module.prop" ] && [ ! -f "${_mfd}disable" ]; then
          if grep -qi "MiFontOverlay" "${_mfd}module.prop" 2>/dev/null; then
            _mfn=$(grep "^name=" "${_mfd}module.prop" 2>/dev/null | cut -d= -f2)
            mifont_status="ACTIVE via $_mfn ✅"
            break
          fi
        fi
      done
    fi
  else
    mifont_status="N/A (AOSP / Not HyperOS — not required) ✅"
  fi
  echo "MiFontOverlay   : $mifont_status"

  # gbl_root_canoe check
  canoe_status="NOT DETECTED"
  [ -e "/dev/block/by-name/efisp" ] && canoe_status="DETECTED (efisp partition)"
  [ -d "/data/adb/modules/gbl_root_canoe" ] && canoe_status="DETECTED (module installed)"
  _vb=$(getprop ro.boot.verifiedbootstate 2>/dev/null)
  if [ "$_vb" = "green" ] && [ "$ROOT_MGR" != "Unknown" ]; then
    # green + root is normal on KernelSU NEXT — only note if canoe not already detected
    if [ "$canoe_status" = "NOT DETECTED" ]; then
      canoe_status="NOT DETECTED (green+root is normal for KernelSU NEXT)"
    fi
  fi
  echo "gbl_root_canoe  : $canoe_status"

  # OverlayFS kernel support
  if grep -q "overlay" /proc/filesystems 2>/dev/null; then
    echo "Kernel OverlayFS: SUPPORTED ✅"
  else
    echo "Kernel OverlayFS: NOT SUPPORTED ❌ (CONFIG_OVERLAY_FS missing)"
  fi

  # fonts_customization.xml MIUI emoji ref check
  for _fcx in /product/etc/fonts_customization.xml /system/product/etc/fonts_customization.xml; do
    if [ -f "$_fcx" ]; then
      _miui_refs=$(grep -c "MiuiColorEmoji\|MiuiEmoji" "$_fcx" 2>/dev/null || echo "0")
      if [ "$_miui_refs" -gt 0 ]; then
        echo "fonts_custom.xml: ⚠ $_fcx has $_miui_refs MIUI emoji refs (overlay may not be active)"
      else
        echo "fonts_custom.xml: ✅ $_fcx — no MIUI emoji refs (OK)"
      fi
    fi
  done

  # /data/fonts/config status
  if [ -d "/data/fonts/config" ]; then
    _dfc=$(ls -1A /data/fonts/config/ 2>/dev/null | wc -l)
    echo "/data/fonts/cfg : $_dfc files"
  fi
  echo ""
  echo "─── [6. STAGE LOG: INSTALLATION (install.log)] ───────────────────────────"
  [ -f "$MODDIR/install.log" ] && cat "$MODDIR/install.log" 2>/dev/null || echo "install.log not found."
  echo ""
  echo "─── [7. STAGE LOG: PRE-MOUNT (post-fs-data.log)] ─────────────────────────"
  [ -f "$MODDIR/post-fs-data.log" ] && cat "$MODDIR/post-fs-data.log" 2>/dev/null || echo "post-fs-data.log not found."
  echo ""
  echo "─── [8. STAGE LOG: POST-MOUNT (post-mount.log)] ───────────────────────────"
  [ -f "$MODDIR/post-mount.log" ] && cat "$MODDIR/post-mount.log" 2>/dev/null || echo "post-mount.log not found."
  echo ""
  echo "─── [9. STAGE LOG: BOOT-COMPLETED (boot-completed.log)] ──────────────────"
  [ -f "$MODDIR/boot-completed.log" ] && cat "$MODDIR/boot-completed.log" 2>/dev/null || echo "boot-completed.log not found."
  echo ""
  echo "─── [10. STAGE LOG: SERVICE RUNTIME (service.log - tail 120)] ─────────────"
  [ -f "$MODDIR/service.log" ] && tail -n 120 "$MODDIR/service.log" 2>/dev/null || echo "service.log not found."
  echo ""
  echo "================================================================================"
  echo "                  END OF DIAGNOSTIC BUNDLE"
  echo "================================================================================"
} > "$REPORT_FILE" 2>/dev/null

exported_target=""
if [ -d "/sdcard/Download" ]; then
  cp -f "$REPORT_FILE" "$SD_REPORT" 2>/dev/null && chmod 644 "$SD_REPORT" 2>/dev/null
  exported_target="$SD_REPORT"
fi
if [ -z "$exported_target" ] && [ -d "/sdcard" ]; then
  cp -f "$REPORT_FILE" "$SD_FALLBACK" 2>/dev/null && chmod 644 "$SD_FALLBACK" 2>/dev/null
  exported_target="$SD_FALLBACK"
fi

echo "[✓] Diagnostic report created successfully!"
if [ -n "$exported_target" ]; then
  echo "[✓] File exported to: $exported_target"
  echo "    (You can access this directly from your phone's Files or Downloads app)"
else
  echo "[✓] File saved to: $REPORT_FILE"
fi
echo ""
echo "Please attach this report to your GitHub Issue:"
echo "https://github.com/antoniomalheirs/Sound_And_Emoji_IOS/issues"
echo "================================================================================"
