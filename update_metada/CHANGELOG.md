## Magisk, KernelSU, KernelSU Next & APatch — Sound_And_Emoji_IOS

*  Systemlessly replaces Emoji and Sounds with iOS Style. Compatible with Magisk, KernelSU, KernelSU Next, and APatch.

# Changelogs

#### V1.4.7 — The REAL Stories Keyboard Flicker Fix (AOSP & Custom ROMs)
- **CRITICAL FIX (SwiftKey / Gboard Crash in Stories):** The keyboard flicker issue when replying to Stories was actually caused by the module aggressively replacing the internal emoji fonts of third-party keyboards (`com.touchtype.swiftkey` and `com.google.android.inputmethod.latin`). When Instagram Stories triggered a rich-text response, the keyboard tried to load its internal font, encountered a locked 30MB file, and crashed. Keyboards have now been EXCLUDED from the internal `/data/data` scan. They will now safely fall back to the system iOS font without crashing.

#### V1.4.6 — The Ultimate HyperOS Instagram Crash Fix (Emoji Watcher Daemon)
- **CRITICAL FIX (HyperOS Stories Crash):** Completely solved the Instagram Stories crash/flicker when replying with emojis. On HyperOS, setting `FacebookEmoji.ttf` to read-only (`chmod 444`) caused an unhandled `Permission Denied` exception in the app's font downloader, crashing the input connection. The file is now fully writable (`chmod 644`) so Instagram's downloader succeeds without crashing.
- **NEW (Meta Emoji Watcher Daemon):** Since the file is now writable, Instagram will try to redownload and overwrite the iOS emojis with the Android ones. To counter this, `service.sh` now spawns an extremely lightweight background daemon that silently watches for font overwrites and instantly restores the iOS emojis, ensuring permanent iOS emojis without breaking the app.

#### V1.4.5 — Instagram Stories Emoji Picker Fix & HyperOS Dual Apps Support
- **CRITICAL FIX (SwiftKey/Gboard Crash in Stories):** Changed the SELinux context of the replaced `FacebookEmoji.ttf` from `app_data_file` to `system_file`. Previously, when the Instagram Stories editor passed the font to third-party keyboards to render the emoji picker, the keyboard's process was blocked by SELinux from reading Instagram's private app data, causing the keyboard to crash and flicker instantly. It now works flawlessly.
- **NEW:** Support for HyperOS and MIUI "Dual Apps". The module now iterates over `/data/user/*` instead of just `/data/user/0/`, ensuring emojis are replaced in cloned/secondary applications.
- **CRITICAL FIX (Stories Keyboard):** The font download directory block (`files/fonts`) has been reverted to affect ONLY Messenger (`com.facebook.orca`). The global block was preventing Instagram from loading typography fonts in Story Mode, which caused the keyboard to disappear when trying to type.

#### V1.4.2 — Version Display Fix on Installation
- **FIXED:** The installation banner was displaying "v1.4.0" instead of "v1.4.1" in `customize.sh`, causing Magisk to show the wrong version in the module list and preventing the system from recognizing the update.
- **IMPROVED:** The installation banner now dynamically reads the version from `module.prop` instead of using a hardcoded value, preventing this type of bug in future releases.

#### V1.4.1 — Definitive Emoji Fix for Facebook, Messenger, and Meta Apps
- **CRITICAL:** Facebook and Messenger were ignoring the emoji replacement because they store fonts in multiple internal directories, not just in `app_ras_blobs`.
- **NEW:** Nuclear approach — the module now scans **ALL** `*emoji*.ttf` files in `/data/data/` and `/data/user/0/` and replaces them with the iOS font.
- **NEW:** Disabled the Google Play Services Font Provider (`FontsProvider` + `UpdateSchedulerService`) that was re-downloading the default Android font in the background, undoing the module's changes.
- **NEW:** Cleaned `/data/fonts/` and GMS font directories across all boot stages.
- **NEW:** Blocked the Messenger font download directory (`files/fonts`) with `chmod 000` to prevent re-downloads.
- **FIXED:** Removed the use of `chattr +i` (immutable) on emoji files, which was causing crashes on Instagram (Permission Denied). The lock now relies solely on file permissions.
- **NEW:** Automatic force-stop of all Meta apps after emoji replacement.
- **NEW:** Detailed logging in `service.log` within the module folder for debugging.
- **IMPROVED:** Expanded list of Meta apps: Facebook, Messenger, Facebook Lite, Messenger Lite, Instagram, InstaPro.

#### V1.4.0 — Full Compatibility Fix for KernelSU / KernelSU Next / Magisk
- **CRITICAL:** Fixed `system.prop` that used Windows line endings (CRLF). `resetprop` does not interpret CRLF, resulting in NO sound properties being applied. Converted to LF (Unix).
- **CRITICAL:** Removed obsolete flags from legacy Magisk (`SKIPMOUNT`, `PROPFILE`, `POSTFSDATA`, `LATESTARTSERVICE`) from `customize.sh`. These were ignored by KernelSU and modern Magisk.
- **CRITICAL:** Added `post-mount.sh` for KernelSU/KernelSU Next. The Facebook emoji bind mounts were in `post-fs-data.sh`, which executes BEFORE OverlayFS mounts — causing the source files to not exist.
- **NEW:** Added `boot-completed.sh` for KernelSU. Media scanning now uses the native KernelSU hook instead of manual polling with `sleep`.
- **NEW:** Added `sepolicy.rule` with SELinux rules for audioserver, mediaserver, and apps (Facebook, Gboard) to read the mounted files.
- **NEW:** Automatic metamodule detection during KernelSU installation. Warns the user if `meta-overlayfs` is not found.
- **IMPROVED:** `service.sh` rewritten with conditional logic — works as a full fallback in Magisk and lightweight mode in KernelSU.
- **IMPROVED:** `post-fs-data.sh` simplified to only perform safe pre-mount stage operations (/data/ cleanup).
- **IMPROVED:** `customize.sh` now uses `set_perm_recursive` with an explicit SELinux context.
- **IMPROVED:** More aggressive Gboard cache cleanup during installation (includes emoji + superpacks).
- **FIXED:** Added Instagram (`com.instagram.android`, `com.instapro.android`) to the list of apps that use `FacebookEmoji.ttf` to overwrite the individual rendering (`app_ras_blobs`) of Meta apps.

#### V1.3.1 Build for Module
- **FIXED:** iOS Emojis not appearing on Gboard. The module now clears dynamically downloaded stock fonts (`/data/fonts/files`) and Gboard caches on boot and installation to enforce iOS emojis.

#### V1.3.0 — Major Update: Forcing Media Scan (KernelSU/OverlayFS Fix)
- **CRITICAL:** KernelSU Next users with active OverlayFS reported that notifications, alarms, and ringtones were still not appearing in the Settings interface, even with correct metadata.
- **ROOT CAUSE:** KernelSU OverlayFS overlays (mounts) the media folders **after** Android has already booted and done the initial file scan (`MediaScanner`). Therefore, Android skips the folder before our files exist there and considers the folder empty.
- **SOLUTION:** Created a dynamic mechanism in `service.sh` (Late Start Service). The module now waits for the phone to finish the entire boot cycle, pauses for 10 seconds for the interface to load, and fires silent Broadcast `Intents` ordering the MediaStore to manually index all our `.ogg` and `.wav` audio files one by one. This ensures Android lists everything when Settings are opened.
- **CRITICAL:** Users reported that Alarms, Notifications, and Ringtones were not appearing in the Android Settings list.
- **SOLUTION:** The modern Android MediaStore requires audio files to have the readable `TITLE` metadata tag injected into the file binary, otherwise it hides the sound from the settings interface. As of this version, all 76 files (`.ogg` and `.wav`) have been injected with ID3 tags (e.g., `Title: iOS Default Ringtone`), ensuring they instantly appear in any system's selection menu.
- **CRITICAL / NEW:** On very recent ROMs like Axion OS (Android 16 QPR1) or interfaces heavily modified by Xiaomi (HyperOS/MIUI), the system stopped blindly reading the `/ui/` folder and started reading hardcoded configurations in `build.prop` (`ro.config.*_sound`).
- **SOLUTION:** The module now actively injects `system.prop`. It overwrites global Android properties the moment the phone boots. We now explicitly *order* Android 15/16 to use the module files, regardless of which phone or Custom ROM you are using (e.g., `ro.config.lock_sound=ui/Lock.ogg`, `ro.config.wireless_charging_started_sound=...`).
- **NEW:** To ensure 100% compatibility with OEM cameras and Custom ROMs (as requested by the user), **all 38 sounds now have TWO versions: `.ogg` and `.wav`**. This covers both pure AOSP source code and manufacturer ROMs that require uncompressed audio (`.wav`).
- **NEW:** Added an *Aliasing* routine in the installation script. Some ROMs read `lock.ogg` (lowercase) and others `Lock.ogg` (uppercase). The Android system is case-sensitive. Now, the module proactively mirrors `Lock` -> `lock`, `Unlock` -> `unlock` and `camera_click` -> `camera_shutter` directly in Android blindly, ensuring the ROM always finds the click!
- **CRITICAL:** The original Apple `.m4a` audio files contained cover art. When converted to `.ogg`, `ffmpeg` preserved these images as "video streams" within the audio file. Android's sound architecture (SoundPool) immediately rejects any system file that has multiple streams or video components.
- **SOLUTION:** All 38 files were purely re-encoded (strict audio), removing clandestine video streams and incompatible metadata. They are now clean OGG Vorbis files, guaranteed to play on Android.
- **CRITICAL:** Added SELinux context definition (`u:object_r:system_file:s0`) to all audios and fonts. Without this, Android's `mediaserver` didn't have permission to read the files and the original sounds weren't replaced.
- **CRITICAL:** Fixed a bug where the double Android API check failed (returned `""`), preventing the correct folder from being used during installation.
- **IMPROVED:** Guaranteed that sounds will always be installed. If the API is ≤11 or unknown, the module now forces mirroring of `system/product/media` to `system/media` to be absolutely certain it works.
- **General Improvement:** Total replacement of all audios with verified iOS originals in `.ogg` Vorbis (44100Hz).
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