#!/system/bin/sh
# Sound_And_Emoji_IOS — customize.sh
# Universal installer for Magisk, KernelSU, KernelSU Next & APatch
#
# This script is SOURCED (not executed) by the module installer
# after files are extracted and default permissions are applied.

# ─── Helper Functions ────────────────────────────────────────────────

# Check if a package is installed
package_installed() {
  pm list packages 2>/dev/null | grep -q "^package:${1}$"
}

# Detect the root environment
detect_environment() {
  if [ -n "$KSU" ]; then
    if [ -n "$KSU_VER_CODE" ] && [ "$KSU_VER_CODE" -ge 20000 ] 2>/dev/null; then
      ENV_NAME="KernelSU Next"
    else
      ENV_NAME="KernelSU"
    fi
    ENV_VER="$KSU_VER"
    ENV_VER_CODE="$KSU_VER_CODE"
    IS_KSU=true
  elif [ -n "$APATCH" ]; then
    ENV_NAME="APatch"
    ENV_VER="$APATCH_VER"
    ENV_VER_CODE="$APATCH_VER_CODE"
    IS_KSU=false
  else
    ENV_NAME="Magisk"
    ENV_VER="$MAGISK_VER"
    ENV_VER_CODE="$MAGISK_VER_CODE"
    IS_KSU=false
  fi
}

# Read version dynamically from module.prop to avoid hardcoded version mismatches
MOD_VER=$(grep "^version=" "$MODPATH/module.prop" | cut -d= -f2)
[ -z "$MOD_VER" ] && MOD_VER="unknown"

ui_print " "
ui_print "╔═══════════════════════════════════════╗"
ui_print "║       Sound_And_Emoji_IOS ${MOD_VER}      ║"
ui_print "║          by SentinelData               ║"
ui_print "╚═══════════════════════════════════════╝"
ui_print " "

# ── Detect root environment ──
detect_environment
ui_print "[✓] Ambiente: $ENV_NAME"
ui_print "[✓] Versão: $ENV_VER (code: $ENV_VER_CODE)"
ui_print " "
sleep 1

# ── KernelSU metamodule check ──
if [ "$IS_KSU" = true ]; then
  METAMODULE_FOUND=false

  # Check for meta-overlayfs
  if [ -d "/data/adb/modules/meta-overlayfs" ] && [ ! -f "/data/adb/modules/meta-overlayfs/disable" ]; then
    METAMODULE_FOUND=true
    ui_print "[✓] Metamodule detectado: meta-overlayfs"
  fi

  # Check for hybrid mount or other known metamodules
  for meta_dir in /data/adb/modules/*/; do
    if [ -f "${meta_dir}module.prop" ]; then
      if grep -q "metamodule=1" "${meta_dir}module.prop" 2>/dev/null; then
        if [ ! -f "${meta_dir}disable" ]; then
          METAMODULE_FOUND=true
          meta_name=$(grep "^name=" "${meta_dir}module.prop" | cut -d= -f2)
          ui_print "[✓] Metamodule detectado: $meta_name"
        fi
      fi
    fi
  done

  if [ "$METAMODULE_FOUND" = false ]; then
    ui_print " "
    ui_print "╔═══════════════════════════════════════╗"
    ui_print "║  ⚠ AVISO: Metamodule não encontrado!  ║"
    ui_print "║                                        ║"
    ui_print "║  KernelSU/KSU Next precisa de um       ║"
    ui_print "║  metamodule (ex: meta-overlayfs)       ║"
    ui_print "║  para montar arquivos em /system/.     ║"
    ui_print "║                                        ║"
    ui_print "║  Instale-o ANTES de reiniciar.         ║"
    ui_print "╚═══════════════════════════════════════╝"
    ui_print " "
    sleep 2
  else
    ui_print "[*] Dica KSU Next / Android 16+: Se o módulo não"
    ui_print "    funcionar, tente alternar o método de"
    ui_print "    montagem para Magic Mount no gerenciador."
  fi
fi

# ── Detect Android version for sound path strategy ──
if [ -z "$API" ]; then
  API=$(getprop ro.build.version.sdk)
fi
if [ -z "$API" ]; then
  API=0
fi
ANDROID_VER=$(getprop ro.build.version.release)
ui_print "[✓] Android $ANDROID_VER (API $API)"

# ─── Universal Audio Path Detection ─────────────────────────────────
# Detect ALL possible audio base paths on the device. Different OEMs
# and custom ROMs place audio files in different partitions:
#   - /system/product/media/audio  (AOSP Android 12+, most ROMs)
#   - /product/media/audio         (separate product partition)
#   - /system_ext/media/audio      (system extension partition)
#   - /vendor/media/audio          (vendor/OEM partition)
#   - /odm/media/audio             (ODM partition)
#   - /system/media/audio          (legacy AOSP path)
#   - /omc/media/audio             (Samsung CSC)
#   - /system/omc/media/audio      (Samsung CSC alt)
#   - /system/prism/media/audio    (Samsung regional)

SYSTEM_AUDIO_PATHS=""
SYSTEM_AUDIO_COUNT=0
for candidate in \
  /system/product/media/audio \
  /product/media/audio \
  /system_ext/media/audio \
  /vendor/media/audio \
  /odm/media/audio \
  /system/media/audio \
  /omc/media/audio \
  /system/omc/media/audio \
  /system/prism/media/audio \
  /optics/media/audio \
  /system/optics/media/audio \
  /my_product/media/audio \
  /my_region/media/audio \
  /my_stock/media/audio \
  /my_heytap/media/audio \
  /my_carrier/media/audio \
  /vgc/media/audio \
  /cust/media/audio; do
  if [ -d "$candidate" ]; then
    SYSTEM_AUDIO_PATHS="$SYSTEM_AUDIO_PATHS $candidate"
    SYSTEM_AUDIO_COUNT=$((SYSTEM_AUDIO_COUNT + 1))
    ui_print "[✓] Caminho de áudio encontrado: $candidate"
  fi
done

if [ "$SYSTEM_AUDIO_COUNT" -eq 0 ]; then
  ui_print "[!] Nenhum caminho de áudio do sistema encontrado!"
  ui_print "[*] Usando caminhos padrão AOSP..."
  SYSTEM_AUDIO_PATHS="/system/product/media/audio /system/media/audio"
fi

# ── Set up primary module audio directory ──
# By default, the installer extracts to system/product/media/audio as defined in the ZIP.
SOUND_DIR_PROD="$MODPATH/system/product/media/audio"
SOUND_DIR_LEGACY="$MODPATH/system/media/audio"
SOUND_DIR="$SOUND_DIR_PROD"

ui_print "[✓] Diretório base de áudios preparado"

UI_COUNT=$(find "$SOUND_DIR/ui" -type f -name "*.ogg" 2>/dev/null | wc -l)
ui_print "[✓] Sons de UI instalados: $UI_COUNT arquivos (.ogg)"

# ─── Robust OEM/Manufacturer Detection ──────────────────────────────
# Detect manufacturer/ROM using MULTIPLE sources to handle custom ROMs
# that strip or rename standard properties.

MANUFACTURER=$(getprop ro.product.manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]')
BRAND=$(getprop ro.product.brand 2>/dev/null | tr '[:upper:]' '[:lower:]')
FINGERPRINT=$(getprop ro.build.fingerprint 2>/dev/null | tr '[:upper:]' '[:lower:]')
BUILD_DISPLAY=$(getprop ro.build.display.id 2>/dev/null | tr '[:upper:]' '[:lower:]')
BOARD=$(getprop ro.board.platform 2>/dev/null | tr '[:upper:]' '[:lower:]')

# ROM-specific properties
ONEUI_VER=$(getprop ro.build.version.oneui 2>/dev/null)
MIUI_VER=$(getprop ro.miui.ui.version.name 2>/dev/null)
HYPEROS_VER=$(getprop ro.mi.os.version.name 2>/dev/null)
OPPO_ROM=$(getprop ro.oplus.image.my_manifest 2>/dev/null)
LG_ROM=$(getprop ro.lge.build.target_operator 2>/dev/null)
EMUI_VER=$(getprop ro.build.version.emui 2>/dev/null)
MAGIC_UI=$(getprop ro.build.version.magic 2>/dev/null)
NOTHING_VER=$(getprop ro.nothing.build.os.version 2>/dev/null)
VIVO_VER=$(getprop ro.vivo.os.version 2>/dev/null)
FUNTOUCH_VER=$(getprop ro.vivo.product.release 2>/dev/null)
SONY_VER=$(getprop ro.sony.ircc.model 2>/dev/null)
ASUS_VER=$(getprop ro.asus.ui.version 2>/dev/null)
TRANSSION_VER=$(getprop ro.oem.key1 2>/dev/null)
HIOS_VER=$(getprop ro.os.version.release 2>/dev/null)
HONOR_OS=$(getprop ro.honor.build.os 2>/dev/null)
NOKIA_HMD=$(getprop ro.hmd.version 2>/dev/null)

# Composite detection flags
IS_SAMSUNG=false
IS_XIAOMI=false
IS_OPPO=false
IS_LG=false
IS_HUAWEI=false
IS_HONOR=false
IS_NOTHING=false
IS_VIVO=false
IS_MOTOROLA=false
IS_GOOGLE=false
IS_SONY=false
IS_ASUS=false
IS_LENOVO=false
IS_ZTE=false
IS_TRANSSION=false
IS_NOKIA=false
IS_MEIZU=false
IS_TCL=false
IS_FAIRPHONE=false

# ── Detect Custom AOSP ROMs (Axion OS, LineageOS, PixelOS, crDroid, EvolutionX, etc.) ──
# On custom AOSP ROMs, hardware properties like ro.product.manufacturer still report
# 'Xiaomi' or 'Samsung', but the operating system is pure AOSP (NOT MIUI, HyperOS, or OneUI).
IS_CUSTOM_AOSP=false
AXION_VER=$(getprop ro.axion.version 2>/dev/null)
LINEAGE_VER=$(getprop ro.lineage.version 2>/dev/null)
CRDROID_VER=$(getprop ro.crdroid.version 2>/dev/null)
EVO_VER=$(getprop ro.evolution.version 2>/dev/null)
AOSP_VERSION=$(getprop ro.rom.version 2>/dev/null)

if [ -n "$AXION_VER" ] || [ -n "$LINEAGE_VER" ] || [ -n "$CRDROID_VER" ] || [ -n "$EVO_VER" ] || [ -n "$AOSP_VERSION" ] || \
   echo "$BUILD_DISPLAY" | grep -qiE "axion|lineage|crdroid|evolution|pixelos|aosp|derp|havoc|resurrection"; then
  IS_CUSTOM_AOSP=true
fi

# Samsung detection — only if genuinely OneUI and NOT an AOSP custom ROM
if [ "$IS_CUSTOM_AOSP" = false ]; then
  if [ -n "$ONEUI_VER" ]; then
    IS_SAMSUNG=true
  elif [ "$MANUFACTURER" = "samsung" ] || [ "$BRAND" = "samsung" ]; then
    if pm list packages 2>/dev/null | grep -q "com.sec.android.app"; then
      IS_SAMSUNG=true
    fi
  fi
fi

# Xiaomi/MIUI/HyperOS detection — ONLY if genuinely MIUI/HyperOS, NEVER for AOSP ROMs on Xiaomi!
if [ "$IS_CUSTOM_AOSP" = false ]; then
  if [ -n "$MIUI_VER" ] || [ -n "$HYPEROS_VER" ]; then
    IS_XIAOMI=true
  elif [ -f "/system/etc/device_features" ] || [ -d "/system/priv-app/MiuiSystemUI" ] || [ -d "/product/priv-app/MiuiSystemUI" ]; then
    IS_XIAOMI=true
  fi
fi

# OPPO/OnePlus/Realme detection
if [ -n "$OPPO_ROM" ]; then
  IS_OPPO=true
elif [ "$MANUFACTURER" = "oppo" ] || [ "$BRAND" = "oneplus" ] || [ "$BRAND" = "realme" ]; then
  IS_OPPO=true
elif [ "$MANUFACTURER" = "oplus" ]; then
  IS_OPPO=true
fi

# LG detection
if [ -n "$LG_ROM" ]; then
  IS_LG=true
elif [ "$MANUFACTURER" = "lge" ] || [ "$MANUFACTURER" = "lg" ]; then
  IS_LG=true
fi

# Huawei detection (now separate from Honor)
if [ -n "$EMUI_VER" ] || [ -n "$MAGIC_UI" ]; then
  if [ "$BRAND" = "honor" ] || [ -n "$HONOR_OS" ]; then
    IS_HONOR=true
  else
    IS_HUAWEI=true
  fi
elif [ "$MANUFACTURER" = "huawei" ] || [ "$BRAND" = "huawei" ]; then
  IS_HUAWEI=true
fi

# Honor detection (independent since 2021)
if [ -n "$HONOR_OS" ]; then
  IS_HONOR=true
elif [ "$MANUFACTURER" = "honor" ] || [ "$BRAND" = "honor" ]; then
  IS_HONOR=true
fi

# Nothing Phone detection
if [ -n "$NOTHING_VER" ]; then
  IS_NOTHING=true
elif [ "$MANUFACTURER" = "nothing" ] || [ "$BRAND" = "nothing" ]; then
  IS_NOTHING=true
fi

# Vivo/iQOO detection
if [ -n "$VIVO_VER" ] || [ -n "$FUNTOUCH_VER" ]; then
  IS_VIVO=true
elif [ "$MANUFACTURER" = "vivo" ] || [ "$BRAND" = "vivo" ] || [ "$BRAND" = "iqoo" ]; then
  IS_VIVO=true
fi

# Motorola detection
if [ "$MANUFACTURER" = "motorola" ] || [ "$BRAND" = "motorola" ]; then
  IS_MOTOROLA=true
fi

# Google/Pixel detection
if [ "$MANUFACTURER" = "google" ] || [ "$BRAND" = "google" ]; then
  IS_GOOGLE=true
elif echo "$FINGERPRINT" | grep -q "google"; then
  IS_GOOGLE=true
fi

# Sony/Xperia detection
if [ -n "$SONY_VER" ]; then
  IS_SONY=true
elif [ "$MANUFACTURER" = "sony" ] || [ "$BRAND" = "sony" ]; then
  IS_SONY=true
elif echo "$FINGERPRINT" | grep -q "sony"; then
  IS_SONY=true
fi

# ASUS/ROG detection
if [ -n "$ASUS_VER" ]; then
  IS_ASUS=true
elif [ "$MANUFACTURER" = "asus" ] || [ "$BRAND" = "asus" ]; then
  IS_ASUS=true
fi

# Lenovo detection
if [ "$MANUFACTURER" = "lenovo" ] || [ "$BRAND" = "lenovo" ]; then
  IS_LENOVO=true
fi

# ZTE/Nubia detection
if [ "$MANUFACTURER" = "zte" ] || [ "$BRAND" = "zte" ] || [ "$BRAND" = "nubia" ] || [ "$MANUFACTURER" = "nubia" ]; then
  IS_ZTE=true
fi

# Tecno/Infinix/Itel (Transsion Holdings) detection
if [ -n "$TRANSSION_VER" ] || [ -n "$HIOS_VER" ]; then
  IS_TRANSSION=true
fi
if [ "$MANUFACTURER" = "tecno" ] || [ "$BRAND" = "tecno" ] || \
   [ "$MANUFACTURER" = "infinix" ] || [ "$BRAND" = "infinix" ] || \
   [ "$MANUFACTURER" = "itel" ] || [ "$BRAND" = "itel" ]; then
  IS_TRANSSION=true
fi

# Nokia/HMD Global detection
if [ -n "$NOKIA_HMD" ]; then
  IS_NOKIA=true
elif [ "$MANUFACTURER" = "hmd global" ] || [ "$MANUFACTURER" = "nokia" ] || [ "$BRAND" = "nokia" ]; then
  IS_NOKIA=true
fi

# Meizu detection
if echo "$BUILD_DISPLAY" | grep -qi "flyme"; then
  IS_MEIZU=true
elif [ "$MANUFACTURER" = "meizu" ] || [ "$BRAND" = "meizu" ]; then
  IS_MEIZU=true
fi

# TCL/Alcatel detection
if [ "$MANUFACTURER" = "tcl" ] || [ "$BRAND" = "tcl" ] || \
   [ "$MANUFACTURER" = "alcatel" ] || [ "$BRAND" = "alcatel" ]; then
  IS_TCL=true
fi

# Fairphone detection
if [ "$MANUFACTURER" = "fairphone" ] || [ "$BRAND" = "fairphone" ]; then
  IS_FAIRPHONE=true
fi

ui_print "[*] Fabricante: $MANUFACTURER | Marca: $BRAND"
[ "$IS_CUSTOM_AOSP" = true ] && ui_print "[✓] Custom AOSP ROM detectada (Axion OS / AOSP)"
[ "$IS_SAMSUNG" = true ] && ui_print "[✓] Samsung/OneUI detectado"
[ "$IS_XIAOMI" = true ] && ui_print "[✓] Xiaomi/MIUI/HyperOS detectado"
[ "$IS_OPPO" = true ] && ui_print "[✓] OPPO/OnePlus/Realme detectado"
[ "$IS_LG" = true ] && ui_print "[✓] LG detectado"
[ "$IS_HUAWEI" = true ] && ui_print "[✓] Huawei/EMUI detectado"
[ "$IS_HONOR" = true ] && ui_print "[✓] Honor/MagicOS detectado"
[ "$IS_NOTHING" = true ] && ui_print "[✓] Nothing Phone detectado"
[ "$IS_VIVO" = true ] && ui_print "[✓] Vivo/iQOO detectado"
[ "$IS_MOTOROLA" = true ] && ui_print "[✓] Motorola detectado"
[ "$IS_GOOGLE" = true ] && ui_print "[✓] Google/Pixel detectado"
[ "$IS_SONY" = true ] && ui_print "[✓] Sony/Xperia detectado"
[ "$IS_ASUS" = true ] && ui_print "[✓] ASUS/ROG detectado"
[ "$IS_LENOVO" = true ] && ui_print "[✓] Lenovo detectado"
[ "$IS_ZTE" = true ] && ui_print "[✓] ZTE/Nubia detectado"
[ "$IS_TRANSSION" = true ] && ui_print "[✓] Tecno/Infinix/Itel detectado"
[ "$IS_NOKIA" = true ] && ui_print "[✓] Nokia/HMD detectado"
[ "$IS_MEIZU" = true ] && ui_print "[✓] Meizu/Flyme detectado"
[ "$IS_TCL" = true ] && ui_print "[✓] TCL/Alcatel detectado"
[ "$IS_FAIRPHONE" = true ] && ui_print "[✓] Fairphone detectado"

# ── Mapeamento Inteligente de Áudios OEM ──
# UNCONDITIONAL: We always create OEM-named copies based on the detected
# manufacturer. This ensures audio works regardless of which partition
# path the ROM actually reads from. Extra files that the ROM doesn't
# look for are simply ignored — no side effects.
ui_print " "
ui_print "[*] Mapeando áudios OEM baseado no fabricante detectado..."

# Helper: create a hardlink/copy of a source audio file with a target name
link_audio() {
  local target="$1"
  local source="$2"

  if [ -f "$SOUND_DIR_PROD/ui/$source" ]; then
    ln "$SOUND_DIR_PROD/ui/$source" "$SOUND_DIR_PROD/ui/$target" 2>/dev/null || \
      cp -af "$SOUND_DIR_PROD/ui/$source" "$SOUND_DIR_PROD/ui/$target" 2>/dev/null
  fi
}

# ── Samsung sounds ──
if [ "$IS_SAMSUNG" = true ]; then
  ui_print "[*] Criando mapeamentos Samsung/OneUI..."
  link_audio "TW_Touch.ogg" "Effect_Tick.ogg"
  link_audio "S_HW_Touch.ogg" "Effect_Tick.ogg"
  link_audio "OneUI_Touch.ogg" "Effect_Tick.ogg"
  link_audio "TW_Screen_Lock.ogg" "Lock.ogg"
  link_audio "TW_Screen_Unlock.ogg" "Unlock.ogg"
  link_audio "TW_Low_Battery.ogg" "LowBattery.ogg"
  link_audio "TW_Battery_caution.ogg" "LowBattery.ogg"
  link_audio "TW_Volume_control.ogg" "VolumeIncremental.ogg"
  link_audio "Shutter.ogg" "camera_click.ogg"
  link_audio "cam_st_flanger.ogg" "camera_focus.ogg"
  link_audio "TW_SIP.ogg" "Effect_Tick.ogg"
  link_audio "TW_Pickup.ogg" "Effect_Tick.ogg"
  link_audio "TW_Hangup.ogg" "Effect_Tick.ogg"
  link_audio "TW_Noti.ogg" "Effect_Tick.ogg"
  link_audio "S_HW_Lock.ogg" "Lock.ogg"
  link_audio "S_HW_Unlock.ogg" "Unlock.ogg"
  link_audio "sec_charger_connection.ogg" "ChargingStarted.ogg"
  link_audio "sec_low_battery.ogg" "LowBattery.ogg"
fi

# ── Xiaomi / HyperOS / MIUI sounds ──
if [ "$IS_XIAOMI" = true ]; then
  ui_print "[*] Criando mapeamentos Xiaomi/MIUI/HyperOS..."
  link_audio "lock.ogg" "Lock.ogg"
  link_audio "unlock.ogg" "Unlock.ogg"
  link_audio "folder_open.ogg" "Effect_Tick.ogg"
  link_audio "Dock.ogg" "Effect_Tick.ogg"
  link_audio "Undock.ogg" "Effect_Tick.ogg"
  link_audio "MiTouch.ogg" "Effect_Tick.ogg"
  link_audio "MiLock.ogg" "Lock.ogg"
  link_audio "MiUnlock.ogg" "Unlock.ogg"
fi

# ── OPPO/OnePlus/Realme sounds ──
if [ "$IS_OPPO" = true ]; then
  ui_print "[*] Criando mapeamentos OPPO/OnePlus/Realme..."
  # OPPO ColorOS
  link_audio "OppoTouch.ogg" "Effect_Tick.ogg"
  link_audio "OppoLock.ogg" "Lock.ogg"
  link_audio "OppoUnlock.ogg" "Unlock.ogg"
  link_audio "ColorOS_Touch.ogg" "Effect_Tick.ogg"
  link_audio "ColorOS_Lock.ogg" "Lock.ogg"
  link_audio "ColorOS_Unlock.ogg" "Unlock.ogg"
  # OnePlus OxygenOS/ColorOS
  link_audio "op_touch.ogg" "Effect_Tick.ogg"
  link_audio "op_lock.ogg" "Lock.ogg"
  link_audio "op_unlock.ogg" "Unlock.ogg"
  link_audio "OnePlus_Touch.ogg" "Effect_Tick.ogg"
  link_audio "OnePlus_Lock.ogg" "Lock.ogg"
  link_audio "OnePlus_Unlock.ogg" "Unlock.ogg"
  # Realme UI
  link_audio "realme_touch.ogg" "Effect_Tick.ogg"
  link_audio "realme_lock.ogg" "Lock.ogg"
  link_audio "realme_unlock.ogg" "Unlock.ogg"
fi

# ── Huawei/EMUI sounds ──
if [ "$IS_HUAWEI" = true ]; then
  ui_print "[*] Criando mapeamentos Huawei/EMUI..."
  link_audio "HwTouch.ogg" "Effect_Tick.ogg"
  link_audio "HwLock.ogg" "Lock.ogg"
  link_audio "HwUnlock.ogg" "Unlock.ogg"
  link_audio "HuaweiTouch.ogg" "Effect_Tick.ogg"
  link_audio "HuaweiLock.ogg" "Lock.ogg"
  link_audio "HuaweiUnlock.ogg" "Unlock.ogg"
fi

# ── Honor/MagicOS sounds (independent from Huawei since 2021) ──
if [ "$IS_HONOR" = true ]; then
  ui_print "[*] Criando mapeamentos Honor/MagicOS..."
  link_audio "HwTouch.ogg" "Effect_Tick.ogg"
  link_audio "HwLock.ogg" "Lock.ogg"
  link_audio "HwUnlock.ogg" "Unlock.ogg"
  link_audio "HonorTouch.ogg" "Effect_Tick.ogg"
  link_audio "HonorLock.ogg" "Lock.ogg"
  link_audio "HonorUnlock.ogg" "Unlock.ogg"
  link_audio "honor_touch.ogg" "Effect_Tick.ogg"
  link_audio "honor_lock.ogg" "Lock.ogg"
  link_audio "honor_unlock.ogg" "Unlock.ogg"
fi

# ── Vivo sounds ──
if [ "$IS_VIVO" = true ]; then
  ui_print "[*] Criando mapeamentos Vivo/iQOO..."
  link_audio "VivoTouch.ogg" "Effect_Tick.ogg"
  link_audio "VivoLock.ogg" "Lock.ogg"
  link_audio "VivoUnlock.ogg" "Unlock.ogg"
  link_audio "vivo_touch.ogg" "Effect_Tick.ogg"
  link_audio "vivo_lock.ogg" "Lock.ogg"
  link_audio "vivo_unlock.ogg" "Unlock.ogg"
fi

# ── Motorola sounds ──
if [ "$IS_MOTOROLA" = true ]; then
  ui_print "[*] Criando mapeamentos Motorola..."
  link_audio "MotoTouch.ogg" "Effect_Tick.ogg"
  link_audio "MotoLock.ogg" "Lock.ogg"
  link_audio "MotoUnlock.ogg" "Unlock.ogg"
  link_audio "moto_touch.ogg" "Effect_Tick.ogg"
  link_audio "moto_lock.ogg" "Lock.ogg"
  link_audio "moto_unlock.ogg" "Unlock.ogg"
fi

# ── Sony/Xperia sounds ──
if [ "$IS_SONY" = true ]; then
  ui_print "[*] Criando mapeamentos Sony/Xperia..."
  link_audio "SonyTouch.ogg" "Effect_Tick.ogg"
  link_audio "SonyLock.ogg" "Lock.ogg"
  link_audio "SonyUnlock.ogg" "Unlock.ogg"
  link_audio "sony_touch.ogg" "Effect_Tick.ogg"
  link_audio "sony_lock.ogg" "Lock.ogg"
  link_audio "sony_unlock.ogg" "Unlock.ogg"
  link_audio "xperia_touch.ogg" "Effect_Tick.ogg"
  link_audio "xperia_lock.ogg" "Lock.ogg"
  link_audio "xperia_unlock.ogg" "Unlock.ogg"
fi

# ── ASUS/ROG sounds ──
if [ "$IS_ASUS" = true ]; then
  ui_print "[*] Criando mapeamentos ASUS/ROG..."
  link_audio "AsusTouch.ogg" "Effect_Tick.ogg"
  link_audio "AsusLock.ogg" "Lock.ogg"
  link_audio "AsusUnlock.ogg" "Unlock.ogg"
  link_audio "asus_touch.ogg" "Effect_Tick.ogg"
  link_audio "asus_lock.ogg" "Lock.ogg"
  link_audio "asus_unlock.ogg" "Unlock.ogg"
fi

# ── ZTE/Nubia sounds ──
if [ "$IS_ZTE" = true ]; then
  ui_print "[*] Criando mapeamentos ZTE/Nubia..."
  link_audio "zte_touch.ogg" "Effect_Tick.ogg"
  link_audio "zte_lock.ogg" "Lock.ogg"
  link_audio "zte_unlock.ogg" "Unlock.ogg"
  link_audio "nubia_touch.ogg" "Effect_Tick.ogg"
  link_audio "nubia_lock.ogg" "Lock.ogg"
  link_audio "nubia_unlock.ogg" "Unlock.ogg"
fi

# ── Tecno/Infinix/Itel (Transsion) sounds ──
if [ "$IS_TRANSSION" = true ]; then
  ui_print "[*] Criando mapeamentos Tecno/Infinix/Itel..."
  link_audio "tecno_touch.ogg" "Effect_Tick.ogg"
  link_audio "tecno_lock.ogg" "Lock.ogg"
  link_audio "tecno_unlock.ogg" "Unlock.ogg"
  link_audio "infinix_touch.ogg" "Effect_Tick.ogg"
  link_audio "infinix_lock.ogg" "Lock.ogg"
  link_audio "infinix_unlock.ogg" "Unlock.ogg"
  link_audio "HiOS_Touch.ogg" "Effect_Tick.ogg"
  link_audio "XOS_Touch.ogg" "Effect_Tick.ogg"
fi

# ── Meizu/Flyme sounds ──
if [ "$IS_MEIZU" = true ]; then
  ui_print "[*] Criando mapeamentos Meizu/Flyme..."
  link_audio "flyme_touch.ogg" "Effect_Tick.ogg"
  link_audio "flyme_lock.ogg" "Lock.ogg"
  link_audio "flyme_unlock.ogg" "Unlock.ogg"
  link_audio "MeizuTouch.ogg" "Effect_Tick.ogg"
  link_audio "MeizuLock.ogg" "Lock.ogg"
  link_audio "MeizuUnlock.ogg" "Unlock.ogg"
fi

# ── Mapeamentos Universais / AOSP / Lowercase (ALWAYS applied) ──
# Essencial para Axion OS, AOSP, Pixel, LineageOS, Motorola e Android 12-16
link_audio "lock.ogg" "Lock.ogg"
link_audio "unlock.ogg" "Unlock.ogg"
link_audio "effect_tick.ogg" "Effect_Tick.ogg"
link_audio "touch.ogg" "Effect_Tick.ogg"
link_audio "dock.ogg" "Effect_Tick.ogg"
link_audio "undock.ogg" "Effect_Tick.ogg"
link_audio "Dock.ogg" "Effect_Tick.ogg"
link_audio "Undock.ogg" "Effect_Tick.ogg"
link_audio "Touch.ogg" "Effect_Tick.ogg"
link_audio "Screen_Lock.ogg" "Lock.ogg"
link_audio "Screen_Unlock.ogg" "Unlock.ogg"
link_audio "CameraClick.ogg" "camera_click.ogg"
link_audio "CameraFocus.ogg" "camera_focus.ogg"
link_audio "Media_Volume.ogg" "VolumeIncremental.ogg"
link_audio "KeypressLock.ogg" "Lock.ogg"
link_audio "KeypressUnlock.ogg" "Unlock.ogg"
link_audio "camera_shutter.ogg" "camera_click.ogg"
link_audio "LowBattery_1.ogg" "LowBattery.ogg"
link_audio "low_battery.ogg" "LowBattery.ogg"
link_audio "ChargingStarted_1.ogg" "ChargingStarted.ogg"
link_audio "charging_started.ogg" "ChargingStarted.ogg"
link_audio "charging_stopped.ogg" "ChargingStopped.ogg"
link_audio "WirelessChargingStarted.ogg" "ChargingStarted.ogg"
link_audio "wireless_charging_started.ogg" "ChargingStarted.ogg"

# Teclado / Keypress (AOSP, Pixel, Axion OS e teclados OEM)
link_audio "keypress_standard.ogg" "KeypressStandard.ogg"
link_audio "keypress_spacebar.ogg" "KeypressSpacebar.ogg"
link_audio "keypress_delete.ogg" "KeypressDelete.ogg"
link_audio "keypress_return.ogg" "KeypressReturn.ogg"
link_audio "keypress_invalid.ogg" "KeypressInvalid.ogg"
link_audio "Keypress_Standard.ogg" "KeypressStandard.ogg"
link_audio "Keypress_Spacebar.ogg" "KeypressSpacebar.ogg"
link_audio "Keypress_Delete.ogg" "KeypressDelete.ogg"
link_audio "Keypress_Return.ogg" "KeypressReturn.ogg"
link_audio "Keypress_Invalid.ogg" "KeypressInvalid.ogg"
link_audio "keypress.ogg" "KeypressStandard.ogg"
link_audio "Keypress.ogg" "KeypressStandard.ogg"
link_audio "video_record.ogg" "VideoRecord.ogg"
link_audio "video_stop.ogg" "VideoStop.ogg"
link_audio "volume_incremental.ogg" "VolumeIncremental.ogg"

ui_print "[✓] Áudios OEM e universais mapeados com sucesso."
ui_print " "

# ── Espelhamento Universal de Áudios para Todas as Partições ──
# Executado APÓS todos os links OEM e universais serem criados em SOUND_DIR_PROD.
ui_print "[*] Espelhando áudios completos para todas as partições..."

# 1. Standalone product partition (KernelSU / APatch / meta-overlayfs)
mkdir -p "$MODPATH/product/media" 2>/dev/null
cp -af "$SOUND_DIR_PROD" "$MODPATH/product/media/" 2>/dev/null
ui_print "[✓] Espelhado para: /product/media/audio"

# 2. Legacy /system/media/audio (Android <= 11 e fallback AOSP)
mkdir -p "$MODPATH/system/media" 2>/dev/null
cp -af "$SOUND_DIR_PROD" "$MODPATH/system/media/" 2>/dev/null
ui_print "[✓] Espelhado para: /system/media/audio"

# 3. system_ext partition (ambos: standalone e sob /system)
mkdir -p "$MODPATH/system_ext/media" 2>/dev/null
cp -af "$SOUND_DIR_PROD" "$MODPATH/system_ext/media/" 2>/dev/null
mkdir -p "$MODPATH/system/system_ext/media" 2>/dev/null
cp -af "$SOUND_DIR_PROD" "$MODPATH/system/system_ext/media/" 2>/dev/null
ui_print "[✓] Espelhado para: /system_ext/media/audio"

# 4. Outros caminhos de áudio detectados no dispositivo
for audio_path in $SYSTEM_AUDIO_PATHS; do
  rel_path="$audio_path"
  case "$rel_path" in
    /system/*) rel_path="${rel_path#/system/}" ;;
    /*) rel_path="${rel_path#/}" ;;
  esac
  mod_dest="$MODPATH/system/$rel_path"
  if [ "$mod_dest" != "$SOUND_DIR_PROD" ] && [ "$mod_dest" != "$MODPATH/system/media/audio" ]; then
    mkdir -p "$(dirname "$mod_dest")" 2>/dev/null
    cp -af "$SOUND_DIR_PROD" "$mod_dest" 2>/dev/null
    ui_print "[✓] Espelhado para: /system/$rel_path"
  fi
done

ui_print " "


# ─── OEM Emoji Detection (Inteligente) ──────────────────────────────
# Two detection modes:
#   1. UPDATE MODE: Old module overlay pollutes /system/fonts with fake fonts.
#      We use ROM properties AND manufacturer detection to determine which
#      emoji fonts the ROM REALLY uses.
#   2. FRESH INSTALL MODE: /system/fonts is clean. Scan it directly.
#
# NotoColorEmoji.ttf is ALWAYS included (covers AOSP/Pixel and any ROM
# that uses the standard Android emoji font).

FONT_FILE="$MODPATH/system/fonts/NotoColorEmoji.ttf"
OEM_FOUND=false

# Helper: create a hardlink (or copy) of the iOS emoji font with a given name
link_emoji() {
  local font_name="$1"
  [ "$font_name" = "NotoColorEmoji.ttf" ] && return
  # Skip if already exists
  [ -f "$MODPATH/system/fonts/$font_name" ] && return
  ln "$FONT_FILE" "$MODPATH/system/fonts/$font_name" 2>/dev/null || \
    cp "$FONT_FILE" "$MODPATH/system/fonts/$font_name" 2>/dev/null
  ui_print "[✓] Mapeado: $font_name"
  OEM_FOUND=true
}

# Standard AOSP companions (always needed on Android 12-16)
link_emoji "NotoColorEmojiFlags.ttf"
link_emoji "NotoColorEmojiLegacy.ttf"

# Check if we are updating over an existing version of this module
OLD_MODULE="/data/adb/modules/Sound_And_Emoji_IOS"
IS_MODULE_UPDATE=false
if [ -d "$OLD_MODULE/system/fonts" ]; then
  IS_MODULE_UPDATE=true
fi

if [ "$IS_MODULE_UPDATE" = true ]; then
  # ── UPDATE MODE ──
  # Old module overlay is still active; /system/fonts contains our fake files.
  # Detect the REAL ROM via system properties AND manufacturer flags.
  ui_print "[*] Atualização detectada — detecção baseada em propriedades da ROM"

  # Samsung — use robust detection (handles custom ROMs like LemonUI)
  if [ "$IS_SAMSUNG" = true ]; then
    ui_print "[*] ROM detectada: Samsung/OneUI (ou baseada)"
    link_emoji "SamsungColorEmoji.ttf"
  fi

  # Xiaomi / MIUI / HyperOS
  if [ "$IS_XIAOMI" = true ]; then
    ui_print "[*] ROM detectada: Xiaomi/MIUI/HyperOS"
    link_emoji "MiuiEmoji.ttf"
  fi

  # OPPO/OnePlus/Realme
  if [ "$IS_OPPO" = true ]; then
    ui_print "[*] ROM detectada: OPPO/OnePlus/Realme"
    link_emoji "OPFontEmoji.ttf"
    link_emoji "OnePlusColorEmoji.ttf"
  fi

  # LG
  if [ "$IS_LG" = true ]; then
    ui_print "[*] ROM detectada: LG"
    link_emoji "LGColorEmoji.ttf"
  fi

  # Huawei
  if [ "$IS_HUAWEI" = true ]; then
    ui_print "[*] ROM detectada: Huawei/EMUI"
    link_emoji "HwColorEmoji.ttf"
  fi

  # Honor (independent — still uses HwColorEmoji.ttf in some builds)
  if [ "$IS_HONOR" = true ]; then
    ui_print "[*] ROM detectada: Honor/MagicOS"
    link_emoji "HwColorEmoji.ttf"
    link_emoji "HonorColorEmoji.ttf"
  fi

  # Meizu (some Flyme builds use custom emoji)
  if [ "$IS_MEIZU" = true ]; then
    ui_print "[*] ROM detectada: Meizu/Flyme"
    link_emoji "MeizuColorEmoji.ttf"
    link_emoji "FlymeEmoji.ttf"
  fi

else
  # ── FRESH INSTALL MODE ──
  # No previous module overlay exists; /system/fonts is the real system.
  # Scan ALL possible font directories for emoji font files.
  ui_print "[*] Instalação limpa — varrendo fontes do sistema..."

  for font_dir in /system/fonts /system_ext/fonts /product/fonts /vendor/fonts; do
    if [ -d "$font_dir" ]; then
      for sys_font in $(ls "$font_dir/" 2>/dev/null | grep -iE "emoji" | grep -iE '\.ttf$'); do
        link_emoji "$sys_font"
      done
    fi
  done
fi

if [ "$OEM_FOUND" = false ]; then
  ui_print "[✓] Nenhuma fonte OEM customizada. Padrão AOSP ativo."
fi
# ── Mirror EMOJI fonts to product & system_ext for Android 12-16 & KernelSU ──
# On Android 12-16 (Axion OS / AOSP), NotoColorEmoji.ttf is often in /product/fonts.
# KernelSU/APatch standalone mounts require $MODPATH/product to overlay the standalone /product partition.
# Magisk requires $MODPATH/system/product.
ui_print "[*] Espelhando fontes de emoji para todas as partições..."

# 1. Standalone product partition (KernelSU / APatch / meta-overlayfs)
mkdir -p "$MODPATH/product/fonts" 2>/dev/null
cp -af "$MODPATH/system/fonts/"* "$MODPATH/product/fonts/" 2>/dev/null

# 2. Magisk product partition
mkdir -p "$MODPATH/system/product/fonts" 2>/dev/null
cp -af "$MODPATH/system/fonts/"* "$MODPATH/system/product/fonts/" 2>/dev/null

# 3. system_ext partition (ambos: standalone e sob /system)
mkdir -p "$MODPATH/system_ext/fonts" 2>/dev/null
cp -af "$MODPATH/system/fonts/"* "$MODPATH/system_ext/fonts/" 2>/dev/null
mkdir -p "$MODPATH/system/system_ext/fonts" 2>/dev/null
cp -af "$MODPATH/system/fonts/"* "$MODPATH/system/system_ext/fonts/" 2>/dev/null

ui_print "[✓] Emojis espelhados para /product/fonts e /system_ext/fonts"
ui_print " "

# ── Clear dynamic font caches & Gboard render cache (ONE TIME, only during installation) ──
ui_print "[*] Limpando fontes dinâmicas e cache do teclado..."
rm -rf /data/fonts/files/* 2>/dev/null
rm -rf /data/system/font_config.xml 2>/dev/null
if [ -d /data/fonts ]; then
  chmod 771 /data/fonts 2>/dev/null
  chown system:system /data/fonts 2>/dev/null
  chcon u:object_r:font_data_file:s0 /data/fonts 2>/dev/null
fi
ui_print "[✓] Cache de fontes dinâmicas limpo"

for gboard_dir in /data/data/com.google.android.inputmethod.latin /data/user/*/com.google.android.inputmethod.latin; do
  if [ -d "$gboard_dir" ]; then
    rm -rf "$gboard_dir/cache"/* 2>/dev/null
    rm -rf "$gboard_dir/code_cache"/* 2>/dev/null
    rm -rf "$gboard_dir/files/GCache"/* 2>/dev/null
    rm -rf "$gboard_dir/files/emoji"/* 2>/dev/null
    rm -rf "$gboard_dir/files/superpacks/emoji"* 2>/dev/null
  fi
done
am force-stop com.google.android.inputmethod.latin 2>/dev/null
ui_print "[✓] Cache do teclado limpo com sucesso"
ui_print " "


# ── OverlayFS support (for Magisk with magic_overlayfs module) ──
if [ -f "/data/adb/modules/magisk_overlayfs/util_functions.sh" ] && \
  /data/adb/modules/magisk_overlayfs/overlayfs_system --test 2>/dev/null; then
  ui_print "[*] Magisk OverlayFS detectado — adicionando suporte"
  . /data/adb/modules/magisk_overlayfs/util_functions.sh
  support_overlayfs && rm -rf "$MODPATH/system"
  ui_print "[✓] OverlayFS configurado"
  ui_print " "
fi

# ── Set permissions ──
# set_perm_recursive applies owner, group, dir perms, file perms, and SELinux context
set_perm_recursive $MODPATH 0 0 0755 0644 u:object_r:system_file:s0

# Garantir permissão de execução (0755) em todos os scripts do módulo
for sh_file in "$MODPATH"/*.sh; do
  [ -f "$sh_file" ] && set_perm "$sh_file" 0 0 0755 u:object_r:system_file:s0
done

# ── Summary ──
sleep 1
ui_print "╔═══════════════════════════════════════╗"
ui_print "║         Instalação Concluída!          ║"
ui_print "║                                        ║"
ui_print "║  ✓ Emojis iOS instalados               ║"
ui_print "║  ✓ Sons iOS instalados ($UI_COUNT UI)          ║"
ui_print "║  ✓ Fonte SF Pro Display instalada      ║"
ui_print "║  ✓ Compatível com $ENV_NAME            ║"
ui_print "║                                        ║"
ui_print "║  Reinicie o dispositivo para aplicar.  ║"
ui_print "╚═══════════════════════════════════════╝"
ui_print " "