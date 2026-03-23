SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true

REPLACE="
"

# ─── Helper Functions ────────────────────────────────────────────────

# Check if a package is installed
package_installed() {
  local package="$1"
  if pm list packages 2>/dev/null | grep -q "^package:${package}$"; then
    return 0
  else
    return 1
  fi
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
  elif [ -n "$APATCH" ]; then
    ENV_NAME="APatch"
    ENV_VER="$APATCH_VER"
    ENV_VER_CODE="$APATCH_VER_CODE"
  else
    ENV_NAME="Magisk"
    ENV_VER="$MAGISK_VER"
    ENV_VER_CODE="$MAGISK_VER_CODE"
  fi
}

# ─── Main Installation ──────────────────────────────────────────────

run_install() {
  ui_print " "
  ui_print "╔═══════════════════════════════════════╗"
  ui_print "║       Sound_And_Emoji_IOS v1.3.1              ║"
  ui_print "║          by SentinelData                      ║"
  ui_print "╚═══════════════════════════════════════╝"
  ui_print " "

  # ── Detect root environment ──
  detect_environment
  ui_print "[✓] Ambiente: $ENV_NAME"
  ui_print "[✓] Versão: $ENV_VER (code: $ENV_VER_CODE)"
  ui_print " "
  sleep 0.5

  # ── Extract module files ──
  ui_print "[*] Extraindo arquivos do módulo..."
  unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2
  ui_print "[✓] Arquivos extraídos"
  ui_print " "

  # ── Detect Android version for sound path strategy ──
  API=$(getprop ro.build.version.sdk)
  if [ -z "$API" ]; then
    API=0
  fi
  ANDROID_VER=$(getprop ro.build.version.release)
  ui_print "[✓] Android $ANDROID_VER (API $API)"

  # By default, modules extract to system/product/media/audio as defined in the ZIP.
  # If Android <= 11, we MUST duplicate those files to system/media/audio.
  # We will do this safely, keeping both paths intact to guarantee it mounts SOMEWHERE.
  
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

  # ── AOSP-standard filenames only ──
  # All UI sound files use EXACTLY the same names as AOSP
  # frameworks/base/data/sounds/effects/ogg/
  # No aliases needed — only canonical AOSP names are shipped.

  # ── Count and verify sound files ──
  UI_COUNT=$(find "$SOUND_DIR/ui" -type f -name "*.ogg" 2>/dev/null | wc -l)
  ui_print "[✓] Sons de UI instalados: $UI_COUNT arquivos (.ogg)"

  # ── OEM Emoji Detection ──
  # We check if the OEM-specific emoji font file ACTUALLY EXISTS in the
  # real /system/fonts/ directory. This is critical because:
  #   - A Xiaomi device running AOSP/LineageOS does NOT have MiuiColorEmoji.ttf
  #   - A Samsung device running AOSP does NOT have SamsungColorEmoji.ttf
  # We only create the replacement if the file exists — otherwise we'd
  # create files that the ROM will never use.
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

  # ── Summary ──
  sleep 0.5
  ui_print "╔═══════════════════════════════════════╗"
  ui_print "║         Instalação Concluída!                  ║"
  ui_print "║                                                ║"
  ui_print "║  ✓ Emojis iOS instalados                      ║"
  ui_print "║  ✓ Sons iOS instalados ($UI_COUNT UI)                ║"
  ui_print "║  ✓ Fonte SF Pro Display instalada             ║"
  ui_print "║  ✓ Compatível com $ENV_NAME                    ║"
  ui_print "║                                                ║"
  ui_print "║  Reinicie o dispositivo para aplicar.          ║"
  ui_print "╚═══════════════════════════════════════╝"
  ui_print " "
}

set_permissions() {
  # Default recursively set permissions to 0755 for dirs, 0644 for files
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Enforce correct SELinux context for all system files
  # This is CRITICAL for android's audioserver to be able to read the files
  if [ -d "$MODPATH/system/product/media/audio" ]; then
    chcon -R u:object_r:system_file:s0 "$MODPATH/system/product/media/audio" 2>/dev/null
  fi
  
  if [ -d "$MODPATH/system/media/audio" ]; then
    chcon -R u:object_r:system_file:s0 "$MODPATH/system/media/audio" 2>/dev/null
  fi
  
  if [ -d "$MODPATH/system/fonts" ]; then
    chcon -R u:object_r:system_file:s0 "$MODPATH/system/fonts" 2>/dev/null
  fi
}

run_install