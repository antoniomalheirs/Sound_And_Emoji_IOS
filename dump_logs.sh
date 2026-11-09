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

  aosp_rom="None (OEM Stock)"

  # Layer 1: System Properties via getprop
  crd_v=$(getprop ro.crdroid.display.version 2>/dev/null)
  [ -z "$crd_v" ] && crd_v=$(getprop ro.crdroid.version 2>/dev/null)
  [ -z "$crd_v" ] && crd_v=$(getprop ro.crdroid.build.version 2>/dev/null)
  [ -z "$crd_v" ] && crd_v=$(getprop ro.cr.version 2>/dev/null)
  crd_v="${crd_v#v}"
  crd_v="${crd_v#V}"

  lin_v=$(getprop ro.lineage.display.version 2>/dev/null)
  [ -z "$lin_v" ] && lin_v=$(getprop ro.lineage.version 2>/dev/null)
  [ -z "$lin_v" ] && lin_v=$(getprop ro.lineage.build.version 2>/dev/null)
  lin_v="${lin_v#v}"
  lin_v="${lin_v#V}"

  axi_v=$(getprop ro.axion.display.version 2>/dev/null)
  [ -z "$axi_v" ] && axi_v=$(getprop ro.axion.version 2>/dev/null)
  axi_v="${axi_v#v}"
  axi_v="${axi_v#V}"

  evo_v=$(getprop ro.evolution.display.version 2>/dev/null)
  [ -z "$evo_v" ] && evo_v=$(getprop ro.evolution.version 2>/dev/null)
  evo_v="${evo_v#v}"
  evo_v="${evo_v#V}"

  b_disp=$(getprop ro.build.display.id 2>/dev/null)
  m_prop=$(getprop ro.modversion 2>/dev/null)
  b_desc=$(getprop ro.build.description 2>/dev/null)
  b_flav=$(getprop ro.build.flavor 2>/dev/null)
  all_prop_str="$m_prop $b_disp $b_desc $b_flav"

  BUILD_PROP_FILES="/system/build.prop /system/etc/build.prop /system_ext/build.prop /system_ext/etc/build.prop /product/build.prop /product/etc/build.prop /vendor/build.prop /odm/etc/build.prop /system/system/build.prop"

  if [ -n "$crd_v" ] || [ -n "$(getprop ro.crdroid.device 2>/dev/null)" ] || echo "$all_prop_str" | grep -qi "crdroid"; then
    aosp_rom="crDroid${crd_v:+ (v$crd_v)}"
  elif [ -n "$lin_v" ] || echo "$all_prop_str" | grep -qi "lineage"; then
    aosp_rom="LineageOS${lin_v:+ (v$lin_v)}"
  elif [ -n "$axi_v" ] || echo "$all_prop_str" | grep -qi "axion"; then
    aosp_rom="Axion OS${axi_v:+ (v$axi_v)}"
  elif [ -n "$evo_v" ] || echo "$all_prop_str" | grep -qi "evolution"; then
    aosp_rom="Evolution X${evo_v:+ (v$evo_v)}"
  elif echo "$all_prop_str" | grep -qi "pixelos"; then
    aosp_rom="PixelOS"
  elif echo "$all_prop_str" | grep -qi "rising"; then
    aosp_rom="RisingOS"
  elif echo "$all_prop_str" | grep -qi "matrixx"; then
    aosp_rom="Project Matrixx"
  elif echo "$all_prop_str" | grep -qi "derp"; then
    aosp_rom="DerpFest"
  fi

  # Layer 2: build.prop files direct inspection
  if [ "$aosp_rom" = "None (OEM Stock)" ]; then
    raw_crd=$(grep -m1 -h -iE "^ro\.crdroid\.(display\.)?version=" $BUILD_PROP_FILES 2>/dev/null | head -n1 | cut -d= -f2)
    if [ -n "$raw_crd" ]; then
      raw_crd="${raw_crd#v}"
      raw_crd="${raw_crd#V}"
      aosp_rom="crDroid (v$raw_crd)"
    elif grep -q -m1 -iE "ro\.crdroid|crdroid" $BUILD_PROP_FILES 2>/dev/null; then
      aosp_rom="crDroid"
    fi

    if [ "$aosp_rom" = "None (OEM Stock)" ]; then
      raw_lin=$(grep -m1 -h -iE "^ro\.lineage\.(display\.)?version=" $BUILD_PROP_FILES 2>/dev/null | head -n1 | cut -d= -f2)
      if [ -n "$raw_lin" ]; then
        raw_lin="${raw_lin#v}"
        raw_lin="${raw_lin#V}"
        aosp_rom="LineageOS (v$raw_lin)"
      elif grep -q -m1 -i "lineage" $BUILD_PROP_FILES 2>/dev/null; then
        aosp_rom="LineageOS"
      fi
    fi

    if [ "$aosp_rom" = "None (OEM Stock)" ]; then
      raw_axi=$(grep -m1 -h -iE "^ro\.axion\.(display\.)?version=" $BUILD_PROP_FILES 2>/dev/null | head -n1 | cut -d= -f2)
      if [ -n "$raw_axi" ]; then
        raw_axi="${raw_axi#v}"
        raw_axi="${raw_axi#V}"
        aosp_rom="Axion OS (v$raw_axi)"
      elif grep -q -m1 -i "axion" $BUILD_PROP_FILES 2>/dev/null; then
        aosp_rom="Axion OS"
      fi
    fi

    if [ "$aosp_rom" = "None (OEM Stock)" ]; then
      raw_evo=$(grep -m1 -h -iE "^ro\.evolution\.(display\.)?version=" $BUILD_PROP_FILES 2>/dev/null | head -n1 | cut -d= -f2)
      if [ -n "$raw_evo" ]; then
        raw_evo="${raw_evo#v}"
        raw_evo="${raw_evo#V}"
        aosp_rom="Evolution X (v$raw_evo)"
      elif grep -q -m1 -i "evolution" $BUILD_PROP_FILES 2>/dev/null; then
        aosp_rom="Evolution X"
      fi
    fi
  fi

  # Layer 3: Filesystem package / priv-app directory inspection
  if [ "$aosp_rom" = "None (OEM Stock)" ]; then
    for p in /system /system_ext /product /system/system_ext /system/product; do
      if [ -d "$p/priv-app/crDroidSettings" ] || [ -d "$p/app/crDroidSettings" ] || [ -d "$p/priv-app/crDroid" ] || [ -d "$p/priv-app/crDroidParts" ] || [ -f "$p/etc/permissions/org.crdroid.xml" ]; then
        aosp_rom="crDroid"
        break
      elif [ -d "$p/priv-app/LineageParts" ] || [ -d "$p/priv-app/LineageSettings" ] || [ -f "$p/etc/permissions/org.lineageos.xml" ]; then
        aosp_rom="LineageOS"
        break
      elif [ -d "$p/priv-app/AxionSettings" ] || [ -d "$p/priv-app/AxionParts" ] || [ -f "$p/etc/permissions/org.axion.xml" ]; then
        aosp_rom="Axion OS"
        break
      elif [ -d "$p/priv-app/Evolver" ] || [ -d "$p/priv-app/EvolutionSettings" ]; then
        aosp_rom="Evolution X"
        break
      fi
    done
  fi

  # Layer 4: Android Package Manager (pm list packages)
  if [ "$aosp_rom" = "None (OEM Stock)" ]; then
    all_pkgs=$(pm list packages 2>/dev/null)
    if echo "$all_pkgs" | grep -qiE "org\.crdroid|com\.crdroid"; then
      aosp_rom="crDroid"
    elif echo "$all_pkgs" | grep -qiE "org\.lineageos"; then
      aosp_rom="LineageOS"
    elif echo "$all_pkgs" | grep -qiE "org\.axion"; then
      aosp_rom="Axion OS"
    elif echo "$all_pkgs" | grep -qiE "com\.evolution|org\.evolution"; then
      aosp_rom="Evolution X"
    elif echo "$all_pkgs" | grep -qiE "org\.pixelos"; then
      aosp_rom="PixelOS"
    elif echo "$all_pkgs" | grep -qiE "org\.derpfest"; then
      aosp_rom="DerpFest"
    elif echo "$all_pkgs" | grep -qiE "org\.rising"; then
      aosp_rom="RisingOS"
    elif echo "$all_pkgs" | grep -qiE "org\.matrixx"; then
      aosp_rom="Project Matrixx"
    fi
  fi

  # Layer 5: Fallbacks
  if [ "$aosp_rom" = "None (OEM Stock)" ]; then
    if [ -n "$(getprop ro.rom.version 2>/dev/null)" ]; then
      aosp_rom="Custom AOSP (v$(getprop ro.rom.version 2>/dev/null))"
    elif [ -z "$(getprop ro.miui.ui.version.name 2>/dev/null)" ] && [ -z "$(getprop ro.mi.os.version.name 2>/dev/null)" ] && [ -z "$(getprop ro.build.version.oneui 2>/dev/null)" ]; then
      if [ ! -d "/system/priv-app/MiuiSystemUI" ] && [ ! -d "/product/priv-app/MiuiSystemUI" ]; then
        case "$(getprop ro.product.manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]')" in
          xiaomi|poco|redmi|samsung) aosp_rom="AOSP Custom / Pure AOSP" ;;
        esac
      fi
    fi
  fi

  echo "Custom ROM        : $aosp_rom"
  echo "ROM Skin          : MIUI=$(getprop ro.miui.ui.version.name 2>/dev/null) | HyperOS=$(getprop ro.mi.os.version.name 2>/dev/null) | OneUI=$(getprop ro.build.version.oneui 2>/dev/null)"
  echo "Root Manager      : $ROOT_MGR"
  echo ""
  echo "─── [1b. ROM IDENTIFICATION AUDIT] ─────────────────────────────────────────"
  echo "Detected Custom ROM: $aosp_rom"
  echo "crDroid props      : display=$(getprop ro.crdroid.display.version 2>/dev/null) | ver=$(getprop ro.crdroid.version 2>/dev/null) | build=$(getprop ro.crdroid.build.version 2>/dev/null) | device=$(getprop ro.crdroid.device 2>/dev/null)"
  echo "Lineage props      : display=$(getprop ro.lineage.display.version 2>/dev/null) | ver=$(getprop ro.lineage.version 2>/dev/null)"
  echo "Axion props        : display=$(getprop ro.axion.display.version 2>/dev/null) | ver=$(getprop ro.axion.version 2>/dev/null)"
  echo "Build Display ID   : $(getprop ro.build.display.id 2>/dev/null)"
  echo "Build Description  : $(getprop ro.build.description 2>/dev/null)"
  echo "Mod Version        : $(getprop ro.modversion 2>/dev/null)"
  echo "build.prop matches : $(grep -h -m1 -iE "^ro\.(crdroid|lineage|axion|evolution)\." /system/build.prop /system_ext/build.prop /product/build.prop 2>/dev/null | tr '\n' ' ')"
  echo "Custom ROM pkgs    : $(pm list packages 2>/dev/null | grep -iE "crdroid|lineage|axion|evolution" | tr '\n' ' ')"
  echo "Priv-app dirs      : $(ls -d /system/priv-app/*crdroid* /system_ext/priv-app/*crdroid* /product/priv-app/*crdroid* /system/priv-app/*crDroid* /system_ext/priv-app/*crDroid* /product/priv-app/*crDroid* 2>/dev/null | tr '\n' ' ')"

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
