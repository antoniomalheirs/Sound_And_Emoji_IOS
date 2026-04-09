## Magisk, KernelSU, KernelSU Next & APatch — Sound_And_Emoji_IOS

*  Systemlessly replaces Emoji and Sounds with iOS Style. Compatible with Magisk, KernelSU, KernelSU Next, and APatch.

# Changelogs

#### V1.4.1 — Fix Definitivo de Emojis no Facebook, Messenger e Apps Meta
- **CRÍTICO:** Facebook e Messenger ignoravam a substituição de emojis porque armazenam fontes em múltiplos diretórios internos, não apenas em `app_ras_blobs`.
- **NOVO:** Abordagem nuclear — o módulo agora varre **TODOS** os arquivos `*emoji*.ttf` em `/data/data/` e `/data/user/0/` e os substitui pela fonte iOS.
- **NOVO:** Desativação do Google Play Services Font Provider (`FontsProvider` + `UpdateSchedulerService`) que ficava re-baixando a fonte padrão do Android por trás, desfazendo o módulo.
- **NOVO:** Limpeza de `/data/fonts/` e diretórios de fontes do GMS em todos os estágios de boot.
- **NOVO:** Bloqueio do diretório de download de fontes do Messenger (`files/fonts`) com `chmod 000` para impedir re-downloads.
- **NOVO:** Arquivos de emoji travados com `chattr +i` (imutáveis) para impedir que os apps da Meta sobrescrevam.
- **NOVO:** Force-stop automático de todos os apps Meta após a substituição de emojis.
- **NOVO:** Logging detalhado em `service.log` dentro da pasta do módulo para debug.
- **MELHORADO:** Lista expandida de apps Meta: Facebook, Messenger, Facebook Lite, Messenger Lite, Instagram, InstaPro.

#### V1.4.0 — Correção Total de Compatibilidade KernelSU / KernelSU Next / Magisk
- **CRÍTICO:** Corrigido `system.prop` que usava line endings Windows (CRLF). O `resetprop` não interpreta CRLF, resultando em NENHUMA propriedade de som sendo aplicada. Convertido para LF (Unix).
- **CRÍTICO:** Removidas flags obsoletas do Magisk antigo (`SKIPMOUNT`, `PROPFILE`, `POSTFSDATA`, `LATESTARTSERVICE`) do `customize.sh`. Estas eram ignoradas pelo KernelSU e Magisk moderno.
- **CRÍTICO:** Adicionado `post-mount.sh` para KernelSU/KernelSU Next. Os bind mounts do Facebook emoji estavam no `post-fs-data.sh`, que executa ANTES do OverlayFS montar — fazendo com que os arquivos fonte não existissem.
- **NOVO:** Adicionado `boot-completed.sh` para KernelSU. O media scanning agora usa o hook nativo do KernelSU em vez de polling manual com `sleep`.
- **NOVO:** Adicionado `sepolicy.rule` com regras SELinux para audioserver, mediaserver e apps (Facebook, Gboard) lerem os arquivos montados.
- **NOVO:** Detecção automática de metamodule durante a instalação no KernelSU. Avisa o usuário se `meta-overlayfs` não for encontrado.
- **MELHORADO:** `service.sh` reescrito com lógica condicional — funciona como fallback completo no Magisk e modo leve no KernelSU.
- **MELHORADO:** `post-fs-data.sh` simplificado para fazer apenas operações seguras no estágio pre-mount (limpeza de /data/).
- **MELHORADO:** `customize.sh` agora usa `set_perm_recursive` com contexto SELinux explícito.
- **MELHORADO:** Limpeza de cache do Gboard mais agressiva durante instalação (inclui emoji + superpacks).
- **FIXED:** Adicionado o Instagram (`com.instagram.android`, `com.instapro.android`) na lista que usa os emojis baseados no `FacebookEmoji.ttf` para sobrescrever a renderização individual (`app_ras_blobs`) dos apps da Meta.

#### V1.3.1 Build for Module
- **FIXED:** iOS Emojis not appearing on Gboard. The module now clears dynamically downloaded stock fonts (`/data/fonts/files`) and Gboard caches on boot and installation to enforce iOS emojis.

#### V1.3.0 — Update Major: Forçando Scan de Mídia (Correção KernelSU/OverlayFS)
- **CRÍTICO:** Usuários de KernelSU Next com OverlayFS ativo reportaram que notificações, alarmes e toques ainda não apareciam na interface de Configurações, mesmo com metadados corretos.
- **MOTIVO ROOT:** O KernelSU OverlayFS sobrepõe (monta) as pastas de mídia **depois** que o Android já ligou e fez o scan inicial de arquivos (`MediaScanner`). Sendo assim, o Android passa reto pela pasta antes dos nossos arquivos existirem ali e considera que a pasta está vazia.
- **SOLUÇÃO:** Criado mecanismo dinâmico de `service.sh` (Late Start Service). Agora o módulo aguarda o celular terminar todo o ciclo de boot, dá um respiro de 10 segundos para a interface carregar, e dispara `Intents` de Broadcast silenciosos ordenando que o MediaStore indexe um por um manualmente todos os nossos áudios `.ogg` e `.wav`. Assim o Android lista tudo na hora que os Ajustes forem abertos.
- **CRÍTICO:** Usuários relataram que Alarmes, Notificações e Toques não apareciam na lista de Configurações do Android. 
- **SOLUÇÃO:** O Android MediaStore moderno exige que os arquivos de áudio tenham obrigatoriamente a tag de metadados legível `TITLE` injetada dentro do binário do arquivo, caso contrário ele oculta o som da interface de configurações. A partir dessa versão, todos os 76 arquivos (`.ogg` e `.wav`) foram injetados com tags ID3 (ex: `Title: iOS Default Ringtone`), garantindo que eles apareçam instantaneamente no menu de seleção de qualquer sistema.
- **CRÍTICO / NOVO:** Em ROMs muito recentes como Axion OS (Android 16 QPR1) ou interfaces fortemente modificadas pela Xiaomi (HyperOS/MIUI), o sistema parou de ler cegamente a pasta `/ui/` e passou a ler configurações escritas em pedra no `build.prop` (`ro.config.*_sound`).
- **SOLUÇÃO:** O módulo agora faz injeção ativa de `system.prop`. Ele sobrescreve as propriedades globais do Android no momento em que o celular liga. Agora nós *ordenamos* explicitamente que o Android 15/16 use os arquivos do módulo, independentemente de qual celular ou Custom ROM você esteja usando (ex: `ro.config.lock_sound=ui/Lock.ogg`, `ro.config.wireless_charging_started_sound=...`).
- **NOVO:** Para garantir 100% de compatibilidade com câmeras OEM e ROMs Custom (como o usuário solicitou), **todos os 38 sons agora possuem DUAS versões: `.ogg` e `.wav`**. Isso cobre tanto o código-fonte puro do AOSP quanto ROMs de fabricantes que exigem áudios em formato não comprimido (`.wav`).
- **NOVO:** Adicionada rotina de *Aliasing* no script de instalação. Algumas ROMs leem `lock.ogg` (minúsculo) e outras `Lock.ogg` (maiúsculo). O sistema Android é case-sensitive. Agora, o módulo espelha proativamente `Lock` -> `lock`, `Unlock` -> `unlock` e `camera_click` -> `camera_shutter` direto no Android, de modo cego, garantindo que a ROM sempre ache o clique!
- **CRÍTICO:** Os arquivos de áudio originais `.m4a` da Apple continham arte de capa (cover art). Quando foram convertidos para `.ogg`, o `ffmpeg` preservou essas imagens como "streams de vídeo" dentro do arquivo de áudio. A arquitetura de som do Android (SoundPool) rejeita imediatamente qualquer arquivo de sistema que tenha múltiplas streams ou componentes de vídeo. 
- **SOLUÇÃO:** Todos os 38 arquivos foram re-encodados de forma pura (strict áudio), removendo streams de vídeo clandestinos e metadados incompatíveis. Agora são arquivos OGG Vorbis limpos, garantidos para tocar no Android.
- **CRÍTICO:** Adicionada definição de contexto SELinux (`u:object_r:system_file:s0`) a todos os áudios e fontes. Sem isso, o `mediaserver` do Android não tinha permissão para ler os arquivos e os sons originais não eram substituídos.
- **CRÍTICO:** Corrigido bug onde a verificação dupla de API do Android falhava (retornava `""`), impedindo com que a pasta correta fosse usada na instalação.
- **MELHORADO:** Garantido que sons serão sempre instalados. Se a API for ≤11 ou desconhecida, o módulo agora força o espelhamento de `system/product/media` para `system/media` para ter certeza absoluta do funcionamento.
- **Melhoria Geral:** Substituição total de todos os áudios por originais verificados do iOS em `.ogg` Vorbis (44100Hz).
- **FIXED:** Camera, camera focus, and screenshot sounds were not being replaced due to incorrect file names.
  - Renamed `CameraClick.ogg` → `camera_click.ogg` (matches AOSP `audio_assets.xml`)
  - Renamed `CameraFocus.ogg` → `camera_focus.ogg`
  - Renamed `screenshot.ogg` → `ui_camera_shutter.ogg`
- **FIXED:** Emoji replacement was broken on Samsung, LG, and HTC devices (variables used before declaration in `post-fs-data.sh`).
- **FIXED:** Gboard cache was being cleared on every boot, causing keyboard startup delay. Now only clears during module installation.
- **IMPROVED:** Rewrote `post-fs-data.sh` — removed all manual `/system/` mounts. The root solution's automatic mount (MagicMount/OverlayFS) now handles everything.
- **IMPROVED:** Rewrote `customize.sh` with dynamic OEM detection.
- **ADDED:** APatch compatibility.
- **ADDED:** KernelSU Next detection and logging.
- **ADDED:** OEM emoji support for Xiaomi/Redmi/POCO, OnePlus/OPPO/Realme, and Huawei/Honor.
- **ADDED:** Dual-path sound installation strategy (supports Android ≤11 and Android 12+).
- **ADDED:** `Trusted.ogg` (Smart Lock unlock sound).
- **ADDED:** `NumberPickerValueChange.ogg` (number picker scroll sound).
- **ADDED:** Enhanced installation UI with detailed progress and summary.

#### V1.1.1 Build for Module
- Minor version bump.

#### V1.1.0 Build for Module
- Update Module files for upstream with iOS 18.4.

#### V1.0.9 Build for Module
- Update customize.sh script for install on Magisk.

#### V1.0.8 Build for Module
- Unlock test sound for vibrations match into lockscreen.

#### V1.0.7 Build for Module
- Created quick uninstall script.

#### V1.0.6 Build for Module
- Implemented user interface(UI) for the module repository webpage.

#### V1.0.5 Build for Module
- Updated Emoji to 18.1.

#### V1.0.4 Build for Module
- Removed some resource files identified as redundant files.

#### V1.0.3 Build for Module
- Updated and removed some resource files identified as redundant files.

#### V1.0.2 Build for Module
- Implemented package update system.

#### V1.0.1 Build for Module
- Initial write the code for the module.

## Credits:

### [topjohnwu](https://github.com/topjohnwu) - For creating Magisk
### [tiann](https://github.com/tiann) - For expanding on KernelSU
### [TheGabrielHoward](https://github.com/TheGabrielHoward/IOS-sounds/tree/master) - For some sounds to replace the Android UI and the idea of creating a module for that
### [dtingley11](https://github.com/dtingley11/KernelSU-iOS-Emoji) - For the code to replace fonts on different Android devices