AUTOMOUNT=true
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
    ui_print "[*] Versão Do Modulo para KernelSU: $KSU_VER"
    ui_print "[*] Versão Do KernelSU: ${KSU_VER_CODE}" 
  else
    ui_print "[*] Ambiente: Magisk"
    ui_print "[*] Versão Do Modulo para Magisk: $MAGISK_VER"
    ui_print "[*] Versão Do Magisk: ${MAGISK_VER_CODE}" 
  fi
  sleep 0.5
  ui_print " "
	ui_print "[*] Enable Post-FS-Data Script"
	ui_print " "
  sleep 1
	ui_print "[*] Instalation Sucess"
}

set_permissions() {
  set_perm_recursive  $MODPATH  0  0  0755  0644
}

run_install