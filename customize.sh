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

# ─── Main Installation ──────────────────────────────────────────────

ui_print " "
ui_print "╔═══════════════════════════════════════╗"
ui_print "║       Sound_And_Emoji_IOS v1.4.0      ║"
ui_print "║          by SentinelData               ║"
ui_print "╚═══════════════════════════════════════╝"
ui_print " "

# ── Detect root environment ──
detect_environment
ui_print "[✓] Ambiente: $ENV_NAME"
ui_print "[✓] Versão: $ENV_VER (code: $ENV_VER_CODE)"
ui_print " "
sleep 0.5

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
    ui_print "║  KernelSU precisa do meta-overlayfs    ║"
    ui_print "║  para montar arquivos em /system/.     ║"
    ui_print "║                                        ║"
    ui_print "║  Instale meta-overlayfs ou outro       ║"
    ui_print "║  metamodule compatível ANTES de        ║"
    ui_print "║  reiniciar o dispositivo.               ║"
    ui_print "╚═══════════════════════════════════════╝"
    ui_print " "
    sleep 2
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

# By default, the installer extracts to system/product/media/audio as defined in the ZIP.
# If Android <= 11, we MUST duplicate those files to system/media/audio.

SOUND_DIR_PROD="$MODPATH/system/product/media/audio"
SOUND_DIR_LEGACY="$MODPATH/system/media/audio"

if [ "$API" -ge 31 ]; then
  ui_print "[✓] Caminho prioritário: system/product/media/audio (Android 12+)"
  SOUND_DIR="$SOUND_DIR_PROD"
else
  ui_print "[*] Android 11 ou anterior detectado — configurando caminho duplo"
  SOUND_DIR="$SOUND_DIR_LEGACY"

  mkdir -p "$SOUND_DIR_LEGACY/ui"
  mkdir -p "$SOUND_DIR_LEGACY/alarms"
  mkdir -p "$SOUND_DIR_LEGACY/notifications"
  mkdir -p "$SOUND_DIR_LEGACY/ringtones"

  if [ -d "$SOUND_DIR_PROD" ]; then
    cp -af "$SOUND_DIR_PROD/ui/"* "$SOUND_DIR_LEGACY/ui/" 2>/dev/null
    cp -af "$SOUND_DIR_PROD/alarms/"* "$SOUND_DIR_LEGACY/alarms/" 2>/dev/null
    cp -af "$SOUND_DIR_PROD/notifications/"* "$SOUND_DIR_LEGACY/notifications/" 2>/dev/null
    cp -af "$SOUND_DIR_PROD/ringtones/"* "$SOUND_DIR_LEGACY/ringtones/" 2>/dev/null
    ui_print "[✓] Sons espelhados para system/media/audio"
  fi
fi
ui_print " "

# ── Count and verify sound files ──
UI_COUNT=$(find "$SOUND_DIR/ui" -type f -name "*.ogg" 2>/dev/null | wc -l)
ui_print "[✓] Sons de UI instalados: $UI_COUNT arquivos (.ogg)"

# ── OEM Emoji Detection ──
# Check if the OEM-specific emoji font file ACTUALLY EXISTS in the
# real /system/fonts/ directory. We only create the replacement if
# the file exists — otherwise we'd create files the ROM will never use.
#
# NotoColorEmoji.ttf is ALWAYS included (covers AOSP/Pixel and any ROM
# that uses the standard Android emoji font).

FONT_FILE="$MODPATH/system/fonts/NotoColorEmoji.ttf"
MANUFACTURER=$(getprop ro.product.manufacturer | tr '[:upper:]' '[:lower:]')
OEM_FOUND=false

ui_print "[*] Fabricante: $MANUFACTURER"
ui_print "[*] Verificando fontes OEM no sistema real..."

# List of known OEM emoji font files to check
OEM_FONTS="SamsungColorEmoji.ttf LGNotoColorEmoji.ttf HTC_ColorEmoji.ttf MiuiColorEmoji.ttf OnePlusEmoji.ttf HuaweiColorEmoji.ttf"

for oem_font in $OEM_FONTS; do
  if [ -f "/system/fonts/${oem_font}" ]; then
    cp "$FONT_FILE" "$MODPATH/system/fonts/${oem_font}"
    ui_print "[✓] Detectado ${oem_font} — substituição criada"
    OEM_FOUND=true
  fi
done

if [ "$OEM_FOUND" = false ]; then
  ui_print "[✓] ROM AOSP/Pixel — usando NotoColorEmoji.ttf padrão"
fi
ui_print " "

# ── Clear Gboard cache and Downloaded Fonts (ONE TIME, only during installation) ──
ui_print "[*] Limpando fontes cacheadas (Gboard/Play Services)..."
rm -rf /data/fonts/files/* 2>/dev/null
ui_print "[✓] Fontes cacheadas removidas"

if [ -d /data/data/com.google.android.inputmethod.latin ]; then
  ui_print "[*] Limpando cache do Gboard..."
  find /data -type d -path '*inputmethod.latin*/*cache*' -exec rm -rf {} + 2>/dev/null
  rm -rf /data/data/com.google.android.inputmethod.latin/files/emoji/* 2>/dev/null
  rm -rf /data/data/com.google.android.inputmethod.latin/files/superpacks/emoji* 2>/dev/null
  am force-stop com.google.android.inputmethod.latin 2>/dev/null
  ui_print "[✓] Cache do Gboard limpo"
else
  ui_print "[*] Gboard não encontrado — pulando limpeza de cache"
fi
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
# set_perm_recursive already applies u:object_r:system_file:s0 by default
set_perm_recursive $MODPATH 0 0 0755 0644

# Enforce correct SELinux context for all system files
# This is CRITICAL for android's audioserver to be able to read the files
if [ -d "$MODPATH/system/product/media/audio" ]; then
  set_perm_recursive "$MODPATH/system/product/media/audio" 0 0 0755 0644 u:object_r:system_file:s0
fi

if [ -d "$MODPATH/system/media/audio" ]; then
  set_perm_recursive "$MODPATH/system/media/audio" 0 0 0755 0644 u:object_r:system_file:s0
fi

if [ -d "$MODPATH/system/fonts" ]; then
  set_perm_recursive "$MODPATH/system/fonts" 0 0 0755 0644 u:object_r:system_file:s0
fi

# ── Summary ──
sleep 0.5
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