# 🍎 Sound & Emoji iOS — Magisk / KernelSU / KernelSu Next Module

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0.12-blueviolet?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/Android-11%20~%2016-brightgreen?style=for-the-badge" alt="Android"/>
  <img src="https://img.shields.io/badge/License-Open%20Source-blue?style=for-the-badge" alt="License"/>
</p>

<p align="center">
  <a href="https://github.com/topjohnwu/Magisk"><img src="https://img.shields.io/badge/Root-Magisk-orange?style=for-the-badge&logo=android" alt="Magisk"/></a>
  <a href="https://github.com/tiann/KernelSU"><img src="https://img.shields.io/badge/Root-KernelSU-green?style=for-the-badge&logo=android" alt="KernelSU"/></a>
  <a href="https://github.com/bmax121/APatch"><img src="https://img.shields.io/badge/Root-KernelSU Next-blue?style=for-the-badge&logo=android" alt="KernelSU Next"/></a>
</p>

<p align="center">
  <b>A high-performance system-level module that brings the complete iOS auditory and visual experience to any rooted Android device.</b>
</p>

<p align="center">
  iOS Sounds • iOS Emojis • SF Pro Display Font • Multi-Root Support
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [What's Included](#-whats-included)
- [Compatibility](#-compatibility)
- [Installation](#-installation)
- [Architecture & Boot Lifecycle](#-architecture--boot-lifecycle)
- [Script Details](#-script-details)
- [Project Structure](#-project-structure)
- [OEM Emoji Support](#-oem-emoji-support)
- [Meta / Facebook Emoji Fix](#-meta--facebook-emoji-fix)
- [Known Limitations](#-known-limitations)
- [OTA Updates](#-ota-updates)
- [Troubleshooting](#-troubleshooting)
- [Changelog](#-changelog)
- [Credits](#-credits)

---

## 🔍 Overview

**Sound_And_Emoji_IOS** is a comprehensive Android root module that systemlessly replaces:

1. **All system sounds** (UI, ringtones, notifications, alarms) with authentic iOS audio
2. **System-wide emojis** with the latest iOS emoji font (including OEM-specific replacements)
3. **System typography** with Apple's **SF Pro Display** font family

The module uses an intelligent multi-stage boot pipeline to ensure 100% persistence across reboots, ROM updates, and aggressive Google Play Services font re-downloads.

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| 🔊 **Complete iOS Sound Set** | 43 audio files covering UI, ringtones, notifications, alarms, camera, NFC, charging, and more |
| 😀 **iOS Emoji Replacement** | System-wide emoji override with latest iOS emoji font (~30MB high-res) |
| 🚩 **Authentic Apple Flags** | 270 genuine iOS flag bitmaps replacing stock Google flags (territories, regional & special flags) |
| 🎨 **UVS Format 14 CMAP** | Native OpenType Format 14 (371 UVS records) restoring default yellow skin tones and missing BMP emojis |
| 🔤 **SF Pro Display Font** | 16 font weights (Regular to Ultralight, with Italic variants) |
| 🏭 **OEM Detection** | Auto-detects Samsung, Xiaomi, LG, HTC, OnePlus, Huawei emoji fonts |
| 📷 **OxygenOS / ColorOS Guard** | Dynamic OEM detection skipping camera resetprop on OPPO/OnePlus/Realme to avoid crashes |
| 📱 **Dual-Path Installation** | Installs to both `/system/product/` and `/system/media/` for max ROM compatibility |
| 🔒 **SELinux Compliant** | Full `u:object_r:system_file:s0` context enforcement + custom SEPolicy rules |
| 🔄 **Anti-Revert System** | Blocks Google Play Services from re-downloading stock emoji fonts |
| 🧹 **Zero-Config Gboard Setup** | Automatic storage data wipe (`pm clear`) during installation — no manual cache clearing needed |
| 📘 **Meta App Fix** | Replaces Facebook, Instagram, and Messenger emoji with iOS versions |
| 🪵 **Built-in Logging** | Detailed `service.log` for debugging |
| ♻️ **OverlayFS Support** | Integrated support for `magisk_overlayfs` module |
| 🔁 **Auto-Update** | In-app update support via `updateJson` |

---

## 📦 What's Included

### 🔊 Sounds (43 files)

<details>
<summary><b>UI Sounds (30 files)</b></summary>

| Sound | File |
| :--- | :--- |
| Lock Screen | `Lock.ogg` |
| Unlock Screen | `Unlock.ogg` |
| Keyboard Standard | `KeypressStandard.ogg` |
| Keyboard Spacebar | `KeypressSpacebar.ogg` |
| Keyboard Delete | `KeypressDelete.ogg` |
| Keyboard Return | `KeypressReturn.ogg` |
| Keyboard Invalid | `KeypressInvalid.ogg` |
| Camera Click | `camera_click.ogg`, `CameraClick.ogg` |
| Camera Focus | `camera_focus.ogg`, `CameraFocus.ogg` |
| Screenshot | `screenshot.ogg` |
| Video Record Start | `VideoRecord.ogg` |
| Video Record Stop | `VideoStop.ogg` |
| Charging Started | `ChargingStarted.ogg` |
| Charging Stopped | `ChargingStopped.ogg` |
| Wireless Charging | `WirelessChargingStarted.ogg` |
| Low Battery | `LowBattery.ogg` |
| NFC Success | `NFCSuccess.ogg` |
| NFC Failure | `NFCFailure.ogg` |
| NFC Transfer Complete | `NFCTransferComplete.ogg` |
| NFC Transfer Initiated | `NFCTransferInitiated.ogg` |
| NFC Initiated | `NFCInitiated.ogg` |
| Smart Lock (Trusted) | `Trusted.ogg` |
| Dock | `Dock.ogg` |
| Undock | `Undock.ogg` |
| Volume Incremental | `VolumeIncremental.ogg` |
| Media Volume | `Media_Volume.ogg` |
| Effect Tick | `Effect_Tick.ogg` |
| In-Call Notification | `InCallNotification.ogg` |

</details>

<details>
<summary><b>Notifications (7 files)</b></summary>

| Sound | File |
| :--- | :--- |
| Default Message | `IOSDefaultMessageNotification.ogg` |
| Calendar Alert | `IOSCalendarAlert.ogg` |
| New Mail | `IOSNewMail.ogg` |
| Reminder Alert | `IOSReminderAlert.ogg` |
| Sent Message | `IOSSentMessage.ogg` |
| iOS Notification 0 | `Ios Notification 0.ogg` |
| iOS Notification 1 | `Ios Notification 1.ogg` |

</details>

<details>
<summary><b>Ringtones (3 files)</b></summary>

| Sound | File |
| :--- | :--- |
| Default (Reflection) | `IOSDefaultRingtone.ogg` |
| Reflection | `IOSReflection.ogg` |
| Sashimi | `IOSSashimi.ogg` |

</details>

<details>
<summary><b>Alarms (3 files)</b></summary>

| Sound | File |
| :--- | :--- |
| Default Alarm | `IOSDefaultAlarm.ogg` |
| Bedtime | `IOSBedtimeAlarm.ogg` |
| Nightstand | `IOSNightstandAlarm.ogg` |

</details>

### 😀 Emoji Fonts (2 files)

| Font | Size | Purpose |
| :--- | :--- | :--- |
| `NotoColorEmoji.ttf` | ~33 MB | System-wide emoji replacement (AOSP/Pixel) with authentic Apple flags & full UVS skin tones |
| `FacebookEmoji.ttf` | ~30 MB | Meta apps emoji replacement (FB, IG, Messenger) |

> [!NOTE]
> **Advanced OpenType & Apple Styling Highlights:**
> - **Authentic iOS Flags:** All 270 flag emojis (including country flags, 10 outlying territories, and 11 special flags) use genuine Apple bitmaps centered at optical coordinates `(4, 0)` with zero Google assets remaining.
> - **OpenType CMAP Format 14 (UVS):** Features 371 default Unicode Variation Sequence records for `0xFE0F`, fully conforming to Android Minikin's `Paint.hasGlyph()` validation. Restores the default neutral yellow skin tone in Gboard's variant popup across all single and multi-person emojis.
> - **BMP Emoji Restorations:** Complete character mapping for Basic Multilingual Plane emojis (❤️ `U+2764`, ☠️ `U+2620`, ⁉️ `U+2049`) guaranteeing visibility in both keyboard layouts and search.

### 🔤 SF Pro Display (16 font weights)

| Weight | Regular | Italic |
| :--- | :--- | :--- |
| Ultralight | ✅ | ✅ |
| Thin | ✅ | ✅ |
| Light | ✅ | ✅ |
| Regular | ✅ | ✅ |
| Medium | ✅ | ✅ |
| Semibold | ✅ | ✅ |
| Bold | ✅ | ✅ |
| Heavy | ✅ | ✅ |

---

## 🔧 Compatibility

### Root Solutions

| Platform | Version | Status |
| :--- | :--- | :--- |
| **Magisk** | 20.0+ | ✅ Full Support |
| **KernelSU** | All | ✅ Full Support (requires metamodule) |
| **KernelSU Next** | 20000+ | ✅ Full Support (requires metamodule) |
| **APatch** | All | ✅ Full Support |

### Android Versions

| Android | API | Status | Notes |
| :--- | :--- | :--- | :--- |
| Android 11 | API 30 | ✅ | Legacy path (`/system/media/audio`) |
| Android 12 | API 31 | ✅ | Product path (`/system/product/media/audio`) |
| Android 12L | API 32 | ✅ | — |
| Android 13 | API 33 | ✅ | — |
| Android 14 | API 34 | ✅ | resetprop fallback for `ro.config.*` |
| Android 15 | API 35 | ✅ | resetprop fallback for `ro.config.*` |
| Android 16 | API 36 | ✅ | resetprop fallback for `ro.config.*` |

### Tested ROMs

Works on AOSP, Pixel, LineageOS, crDroid, EvolutionX, AxionOS, MIUI, HyperOS, OneUI, OxygenOS, ColorOS, and more.

> [!IMPORTANT]
> **KernelSU / KernelSU Next users:** You **MUST** install a metamodule (e.g., `meta-overlayfs`) for the module to mount files into `/system/`. The installer will warn you if none is detected.

---

## 🚀 Installation

1. Download the latest `Sound_And_Emoji_IOS.zip` from [Releases](https://github.com/antoniomalheirs/Sound_And_Emoji_IOS/releases)
2. Open your root manager (**Magisk Manager**, **KernelSU Manager**, or **APatch**)
3. Flash the `.zip` via the **Modules** → **Install from storage** option
4. **Reboot** your device
5. Enjoy the iOS experience! 🎉

> [!NOTE]
> The module clears the Gboard emoji cache during installation. You may notice a brief delay on the first keyboard launch after reboot while Gboard rebuilds its emoji index.

---

## 🏗️ Architecture & Boot Lifecycle

The module uses a sophisticated multi-stage boot pipeline to ensure everything works across all root solutions and Android versions:

```mermaid
graph TD
    subgraph INSTALL["📥 Installation (customize.sh)"]
        I1[Detect Root Environment] --> I2[Detect Android Version]
        I2 --> I3{API ≥ 31?}
        I3 -- Yes --> I4["/system/product/media/audio"]
        I3 -- No --> I5["Mirror to /system/media/audio"]
        I4 --> I6[Detect OEM Fonts]
        I5 --> I6
        I6 --> I7[Clear Gboard Cache]
        I7 --> I8[Set SELinux Contexts]
        I8 --> I9[Apply Permissions]
    end

    subgraph BOOT1["🔒 post-fs-data.sh (Pre-Mount)"]
        B1["Nuke font caches:<br/>/data/fonts<br/>GMS fonts<br/>Gboard emoji<br/>Messenger fonts"]
    end

    subgraph BOOT2["📁 post-mount.sh (After OverlayFS)"]
        B2[Replace ALL *emoji*.ttf in /data] --> B3[Lock Meta app emojis]
        B3 --> B4[Block Messenger font downloads]
        B4 --> B5[Clean GMS font caches]
    end

    subgraph BOOT3["⚙️ service.sh (Late Start)"]
        B6[Wait for boot_completed] --> B7[Clear Gboard cache]
        B7 --> B8["Force resetprop ro.config.*"]
        B8 --> B9[Replace ALL emoji fonts globally]
        B9 --> B10[Lock Meta emoji]
        B10 --> B11[Disable GMS Font Provider]
        B11 --> B12["Media Scanner (Magisk only)"]
    end

    subgraph BOOT4["✅ boot-completed.sh (KSU/APatch)"]
        B13["Force resetprop ro.config.*"] --> B14[Media Scanner broadcast]
    end

    INSTALL --> BOOT1
    BOOT1 --> BOOT2
    BOOT2 --> BOOT3
    BOOT3 --> BOOT4

    style INSTALL fill:#1a1a2e,stroke:#e94560,color:#fff
    style BOOT1 fill:#16213e,stroke:#0f3460,color:#fff
    style BOOT2 fill:#16213e,stroke:#533483,color:#fff
    style BOOT3 fill:#16213e,stroke:#e94560,color:#fff
    style BOOT4 fill:#0f3460,stroke:#00b4d8,color:#fff
```

### Why Multiple Stages?

| Stage | Timing | Purpose |
| :--- | :--- | :--- |
| `post-fs-data.sh` | Before module mount | Clean caches BEFORE system reads them |
| `post-mount.sh` | After OverlayFS mount | Replace app emoji files while apps haven't started |
| `service.sh` | Late start (boot completed) | Force properties, disable GMS, media scan |
| `boot-completed.sh` | After `sys.boot_completed=1` (KSU/APatch) | Re-apply properties that system may have overwritten |

---

## 📜 Script Details

### `customize.sh` — Installation Engine

The installation script adapts to the device environment:

- **Root Detection:** Identifies Magisk, KernelSU, KernelSU Next, or APatch
- **Metamodule Check (KSU):** Warns if `meta-overlayfs` or similar is not installed
- **API-Based Path Selection:** Uses `/system/product/` for Android 12+ or mirrors to `/system/media/` for Android 11
- **OEM Emoji Detection:** Scans `/system/fonts/` for manufacturer-specific emoji fonts and creates replacements only for fonts that actually exist
- **Gboard Full Storage Data Wipe:** Executes `pm clear com.google.android.inputmethod.latin` across all user profiles exclusively during installation, purging `bundled_emoji_provider.db` so all emoji colors, flags, and menus render fresh out-of-the-box without manual user intervention
- **OverlayFS Integration:** Detects and supports `magisk_overlayfs` for restricted partitions
- **SELinux Enforcement:** Applies `u:object_r:system_file:s0` context to all installed files

### `post-fs-data.sh` — Pre-Mount Cache Nuker

Runs BEFORE the module is mounted. Has a strict 10-second timeout.

- Deletes `/data/fonts/` (system font updates)
- Cleans GMS font provider caches
- Clears Gboard emoji caches
- Removes Messenger font download directories

### `post-mount.sh` — Emoji Lock (KSU/APatch)

Runs AFTER OverlayFS/MagicMount has mounted module files.

- **Nuclear font replacement:** Finds ALL `*emoji*.ttf` files in `/data/data/` and `/data/user/0/` and replaces them with the iOS emoji font
- **Meta app lock:** Creates/replaces `FacebookEmoji.ttf` in each Meta app's `app_ras_blobs/` directory with correct ownership and immutable flag
- **Messenger block:** Sets `chmod 000` on Messenger's font download directory
- **GMS cleanup:** Removes cached font files from Google Play Services

### `service.sh` — Late Start Service (Universal)

The main runtime script. Waits for `sys.boot_completed=1` before executing.

- **resetprop:** Force-sets 25+ `ro.config.*` sound properties that Android 14+ may overwrite during boot
- **OxygenOS / ColorOS Camera Protection:** Dynamically checks OEM properties (`ro.oplus.image.my_manifest`, `ro.product.manufacturer`, `ro.product.brand`) to skip camera sound `resetprop` on OPPO, OnePlus, and Realme devices, preventing native camera validation crashes while keeping all iOS UI sounds active
- **Global emoji replacement:** Scans ALL app directories for emoji font files and replaces them
- **Meta emoji lock:** Replaces and locks emoji fonts in Facebook, Instagram, Messenger (+ Lite variants) with `chmod 444`
- **GMS Font Provider Deactivation:** Disables `FontsProvider` and `UpdateSchedulerService` in Google Play Services across all user profiles to prevent stock emoji font re-downloads or Google metadata injection
- **Boot-time Gboard Cache Purge:** Clears Gboard layout, superpacks, and emoji caches during boot so the keyboard re-indexes the system iOS font immediately
- **Media Scanner (Magisk):** Broadcasts `MEDIA_SCANNER_SCAN_FILE` intents for all audio files so they appear in Android's sound picker

### `boot-completed.sh` — Post-Boot Hook (KSU/APatch)

KernelSU and APatch support this hook natively. Provides a clean way to re-apply properties after the system is fully booted.

- Re-applies all `ro.config.*` sound properties via `resetprop` (with OEM camera exclusions for OPPO, OnePlus, and Realme devices)
- Triggers media scanner for ringtones, notifications, and alarms

### `sepolicy.rule` — SELinux Policy

Custom SEPolicy rules that allow:

- `mediaserver` and `audioserver` to read module-mounted audio files
- Untrusted apps (Facebook/Messenger) to read bind-mounted emoji fonts
- Platform apps (Gboard) and GMS to read system emoji fonts

### `system.prop` — System Properties

Declares default ringtone, notification, and alarm properties. Kept for backwards compatibility with older Android versions where `system.prop` is reliably applied during boot.

### `uninstall.sh` — Clean Removal

Removes the module directory from `/data/adb/modules/` on uninstallation.

---

## 📂 Project Structure

```
Sound_And_Emoji_IOS/
├── META-INF/                          # Flashable ZIP metadata
│   └── com/google/android/
│       ├── update-binary             # Magisk module installer
│       └── updater-script            # Required (empty marker)
│
├── system/
│   ├── fonts/                         # Font replacements
│   │   ├── NotoColorEmoji.ttf        # iOS emoji font (system-wide)
│   │   ├── FacebookEmoji.ttf         # iOS emoji for Meta apps
│   │   ├── SF-Pro-Display-Regular.ttf
│   │   ├── SF-Pro-Display-Bold.ttf
│   │   ├── SF-Pro-Display-Medium.ttf
│   │   ├── SF-Pro-Display-Semibold.ttf
│   │   ├── SF-Pro-Display-Light.ttf
│   │   ├── SF-Pro-Display-Thin.ttf
│   │   ├── SF-Pro-Display-Heavy.ttf
│   │   ├── SF-Pro-Display-Ultralight.ttf
│   │   └── ... (+ italic variants)
│   │
│   └── product/media/audio/          # iOS sound files
│       ├── ui/                        # 30 UI sounds
│       ├── notifications/             # 7 notification sounds
│       ├── ringtones/                 # 3 ringtones
│       └── alarms/                    # 3 alarm sounds
│
├── webroot/
│   └── index.html                    # Module manager web UI redirect
│
├── update_metada/
│   ├── update.json                   # OTA update manifest
│   └── CHANGELOG.md                  # Full version history
│
├── customize.sh                      # Installation script
├── post-fs-data.sh                   # Pre-mount cache cleaner
├── post-mount.sh                     # Post-mount emoji lock (KSU/APatch)
├── service.sh                        # Late start service (universal)
├── boot-completed.sh                 # Post-boot hook (KSU/APatch)
├── sepolicy.rule                     # Custom SELinux policies
├── system.prop                       # Default sound properties
├── uninstall.sh                      # Cleanup on removal
└── module.prop                       # Module metadata
```

---

## 🏭 OEM Emoji Support

The module automatically detects and replaces manufacturer-specific emoji fonts. It only creates replacement files for fonts that **actually exist** on your device:

| OEM | Font File | Devices |
| :--- | :--- | :--- |
| Samsung | `SamsungColorEmoji.ttf` | Galaxy S, A, Note, Z series |
| Xiaomi | `MiuiColorEmoji.ttf` | Mi, Redmi, POCO (MIUI/HyperOS) |
| LG | `LGNotoColorEmoji.ttf` | LG V, G series |
| HTC | `HTC_ColorEmoji.ttf` | HTC U, Desire series |
| OnePlus | `OnePlusEmoji.ttf` | OnePlus, OPPO, Realme |
| Huawei | `HuaweiColorEmoji.ttf` | Huawei, Honor |
| AOSP/Pixel | `NotoColorEmoji.ttf` | Pixel, AOSP-based ROMs |

---

## 📘 Meta / Facebook Emoji Fix

Meta apps (Facebook, Instagram, Messenger) use their own bundled emoji font (`FacebookEmoji.ttf`) instead of the system font. The module uses an **aggressive multi-layer approach** to force iOS emojis:

```mermaid
graph LR
    A["🔍 Find ALL *emoji*.ttf<br/>in /data/data/ & /data/user/0/"] --> B["📝 Replace with<br/>iOS emoji font"]
    B --> C["🔒 Apply permissions<br/>(chmod 444)"]
    C --> D["🚫 Block Messenger<br/>font downloads<br/>(chmod 000)"]
    D --> E["⛔ Disable GMS<br/>FontsProvider"]
    E --> F["🔄 Force-stop<br/>Meta apps"]

    style A fill:#1877f2,stroke:#fff,color:#fff
    style B fill:#e94560,stroke:#fff,color:#fff
    style C fill:#533483,stroke:#fff,color:#fff
    style D fill:#0f3460,stroke:#fff,color:#fff
    style E fill:#16213e,stroke:#fff,color:#fff
    style F fill:#1a1a2e,stroke:#fff,color:#fff
```

### Targeted Apps

| App | Package | Status |
| :--- | :--- | :--- |
| Facebook | `com.facebook.katana` | ✅ iOS Emojis |
| Messenger | `com.facebook.orca` | ✅ iOS Emojis |
| Facebook Lite | `com.facebook.lite` | ✅ iOS Emojis |
| Messenger Lite | `com.facebook.mlite` | ✅ iOS Emojis |
| Instagram | `com.instagram.android` | ✅ iOS Emojis |
| InstaPro | `com.instapro.android` | ✅ iOS Emojis |

---

## ⚠️ Known Limitations

### WhatsApp Emojis

WhatsApp **does not use the system emoji font** (`NotoColorEmoji.ttf`). Instead, WhatsApp bundles its own proprietary emoji set directly inside the APK to maintain visual consistency across Android, iOS, and Web platforms. This is a deliberate architectural decision by Meta.

**What this means:**
- ✅ System UI, Gboard, SMS, Chrome, and most apps → **iOS emojis work perfectly**
- ✅ Facebook, Instagram, Messenger → **iOS emojis work** (replaced via module)
- ❌ WhatsApp → **uses its own emojis** (cannot be changed without modifying the APK)

> [!NOTE]
> This is **not a bug in the module** — it is a WhatsApp limitation. The only way to change WhatsApp's emojis would be to use a modified APK (which violates WhatsApp's Terms of Service and may result in account suspension).

### Telegram

Telegram has its own emoji rendering system that can be configured in-app. Check **Settings → Chat Settings → Emoji** to use system emojis.

---

## 🔄 OTA Updates

The module supports in-app updates via the `updateJson` mechanism. Your root manager will automatically check for new versions.

**Update URL:** `https://raw.githubusercontent.com/antoniomalheirs/Sound_And_Emoji_IOS/main/update_metada/update.json`

---

## 🔧 Troubleshooting

<details>
<summary><b>Sounds not changing after reboot</b></summary>

1. Check if `service.log` exists in the module directory (`/data/adb/modules/Sound_And_Emoji_IOS/service.log`)
2. Verify that `resetprop` is working: run `getprop ro.config.ringtone` — it should show `IOSDefaultRingtone.ogg`
3. On Android 14+, the system may override `system.prop` — the module uses `resetprop` as fallback via `service.sh` and `boot-completed.sh`
4. Clear your Settings app cache and check sound settings again

</details>

<details>
<summary><b>Emojis not changing in Gboard</b></summary>

1. Clear Gboard app data: **Settings → Apps → Gboard → Clear Data**
2. Reboot the device
3. Check if `/data/fonts/` directory was removed (it should not exist)
4. Verify the module is enabled in your root manager

</details>

<details>
<summary><b>Facebook/Instagram still showing old emojis</b></summary>

1. Force-stop the app
2. Check `service.log` for errors
3. Verify that the emoji file has read-only permissions: `ls -l /data/data/com.facebook.katana/app_ras_blobs/FacebookEmoji.ttf` — should show `-r--r--r--`
4. If not, reboot — the module re-applies on every boot

</details>

<details>
<summary><b>Sounds/Ringtones not appearing in Settings picker</b></summary>

1. The module triggers MediaScanner after boot — wait ~15 seconds after reboot
2. If still not visible, check if your ROM reads from `/system/product/media/audio/` or `/system/media/audio/`
3. Try clearing the MediaProvider cache: **Settings → Apps → Media Storage → Clear Data** → Reboot

</details>

<details>
<summary><b>KernelSU: Nothing is working</b></summary>

1. **You MUST install a metamodule** (e.g., `meta-overlayfs`) for KernelSU to mount files into `/system/`
2. The installer will show a warning if no metamodule is detected
3. Install `meta-overlayfs` → Reboot → Re-flash this module → Reboot again

</details>

<details>
<summary><b>Gboard: Missing yellow skin tone or emojis locked to light skin</b></summary>

1. In V2.0.12, the neutral yellow skin tone option has been completely restored via OpenType Format 14 CMAP (UVS).
2. If your keyboard was previously locked to a skin tone, long-press any hand or person emoji.
3. Select the first option (the neutral yellow emoji).
4. Due to Gboard's native *One-Tap Skin Tone Preference* feature, Gboard will immediately apply the yellow color globally across all compatible emojis.
5. If the menu still shows only 5 colors, re-flash the module or run `pm clear com.google.android.inputmethod.latin` in Termux/root shell.

</details>

<details>
<summary><b>Gboard: Handshake or multi-person emojis show grey figures</b></summary>

1. Emojis with two people or hands (e.g. handshake 🤝, couples 👯) use Gboard's native 2-step selection matrix.
2. The grey figures are **visual placeholders** waiting for your selection:
   - Row 1: Selects the tone for the left figure (right figure is grey/placeholder).
   - Row 2: Selects the tone for the right figure (left figure is grey/placeholder).
3. To select the default yellow combination for both, simply tap the dual-yellow emoji in the bottom row.

</details>

<details>
<summary><b>Camera app crashes on OnePlus, OPPO, or Realme (OxygenOS / ColorOS)</b></summary>

1. This issue has been fully resolved since V2.0.7.
2. The module automatically identifies OPPO/OnePlus/Realme devices and skips overriding camera properties (`ro.config.camera_*`), preserving full native OplusCamera stability while keeping all iOS UI and system sounds active.

</details>

---

## 📝 Changelog

See the full changelog at [`update_metada/CHANGELOG.md`](update_metada/CHANGELOG.md).

### Latest: v2.0.12

- **Definitive Fix for Yellow Skin Tone & Missing Emojis (Issue #8):** Completely restored default yellow skin tone options for all hand emojis (🖐️, ✌️, ☝️, ✍️), person in suit levitating (🕴️), bunny people (👯‍♂️, 👯‍♀️), and restored missing standalone emojis like red heart (❤️), skull and crossbones (☠️), and exclamation question mark (⁉️) in Gboard.
- **Clean CMAP Format 14 Integration:** Replaced CMAP tables with the official OpenType standard layout: Table 0 as Format 14 (Unicode Variation Sequences, 371 default UVS records for `0xFE0F`) and Table 1 as Format 12 (`platformID=3, platEncID=10`), fully passing Android Minikin's `Paint.hasGlyph()` validation.
- **Disable GMS Fonts Provider:** In `service.sh`, permanently disabled `com.google.android.gms.fonts.provider.FontsProvider` and `UpdateSchedulerService` across all users to stop Google Play Services from serving Google's stock emoji metadata to Gboard.
- **Gboard Complete Storage Data Wipe on Install:** Added complete storage data wipe (`pm clear com.google.android.inputmethod.latin` + full directory purge) in `customize.sh` exclusively during module installation, ensuring Gboard builds a clean index with all colors and emojis out-of-the-box.
- **Automatic Gboard Cache Flush on Boot:** Added automatic clearing of Gboard layout, superpacks, and emoji caches during boot in `service.sh`.

### Previous: v2.0.11

- **Restored Default Yellow Skin Tones & Unicode Variation Sequences (UVS Format 14):** Fixed hand emojis and person emojis displaying only 5 light-to-dark skin tones in Gboard's popup with the default yellow option missing.
- **Root Cause & Minikin Validation:** Identified that Android Minikin queries OpenType `cmap` Format 14 (UVS) for `0xFE0F`. When missing, Minikin returns `false` for `hasGlyph`, causing Gboard to assume the font cannot render the yellow base emoji and hiding it from the variant popup.
- **OpenType Format 14 CMAP Injection:** Embedded an OpenType `cmap` Format 14 subtable (`platformID=0, platEncID=5`) mapping all Unicode emoji variation sequence bases for `0xFE0F`.

### Previous: v2.0.10

- **iOS Flag Emojis & Authentic Apple Styling (Issue #8):** Replaced all flag bitmaps inside `NotoColorEmoji.ttf` with genuine Apple iOS flag bitmaps sourced from `AppleColorEmoji.ttf`.
- **Optical Sizing & Alignment:** All Apple 96×96 emoji assets uniformly resized to 128×128 (exact 4/3 ratio matching regular Apple emojis) and placed on the standard 136×128 transparent canvas at horizontal offset (4, 0). Preserves 100% of Apple's original proportions, margins, baselines, and wave curves without distortion.
- **Territory Mappings & Special Flags:** All 10 outlying territories (UM, CP, EA, DG, AC, TA, HM, SJ, BV, MF) mapped to authentic iOS equivalents. All 11 special flags (England, Scotland, Wales, Rainbow, Transgender, Pirate, Chequered, Triangular, Crossed, White, Black) updated — 270 total flags replaced (0 Google flags remaining).
- **Cleanup:** Removed separate pre-built `NotoColorEmojiFlags.ttf`; `customize.sh` mirrors the complete font to all partitions, and `post-fs-data.sh` / `service.sh` lock `/data/fonts/files/` (`chattr +i`).

### Previous: v2.0.7

- **OxygenOS / ColorOS Camera Fix (Issue #7):** Native camera app (OplusCamera) broke when `resetprop` overrode camera sound properties on OPPO/OnePlus/Realme.
- **Runtime OEM Detection:** Added detection logic via `ro.oplus.image.my_manifest`, `ro.product.manufacturer` (oppo/oplus), and `ro.product.brand` (oneplus/realme).
- **Conditional Camera Property Override:** Camera sound `resetprop` calls are now skipped on OPPO/OnePlus/Realme devices, keeping native camera stability while all other iOS sounds work normally.

### Previous: v2.0.6

- **Flag Emoji Fix (Issue #8):** Locked `/data/fonts/files/` with `chattr +i` to prevent Google Play Services from re-downloading stock `NotoColorEmojiFlags.ttf`. Flag emojis now persist as iOS style across reboots.
- **APEX Font Cache Cleaning:** Watcher daemon now also cleans Android 14+ Mainline font caches that can override system emoji fonts.

### Previous: v2.0.5

- **Touch Sound Preference Preserved (Issue #9):** Removed forced `sound_effects_enabled=1` and `dtmf_tone=1` from `service.sh` and `boot-completed.sh`. The module no longer overrides user settings on reboot.
- **Emoji Persistence (Issue #8):** Extended the background Emoji Watcher Daemon in `service.sh` to monitor and clean `/data/fonts/files/`, wipe Google Play Services font caches, and continuously re-apply iOS emojis across apps without CPU overhead.

### Previous: v2.0.4

- **Universal Android 11~16 & AOSP Support:** Full compatibility with Android 16 (Baklava), Axion AOSP, and custom ROMs without bootloop risks.
- **Safe Pre-Boot & Audio Aliases:** Zero-mount safe `post-fs-data.sh` and `post-mount.sh` execution, complete lowercase keypress audio aliases, and dual-phase `SettingsProvider` and `resetprop` injection.
- **Gboard & Font Protection:** Preserves keyboard preferences (including Sound on Keypress) while clearing dynamic emoji packs and preventing Google Play Services OTA font rollbacks.

### Previous: v1.4.9

### Previous: v1.4.8

- **Absolute Keyboard Flicker Fix:** Replaced the Instagram `FacebookEmoji.ttf` with a standard text font (`Roboto-Regular`) to safely bypass a native `EmojiCompat` crash when replying to Stories, gracefully forcing the app to fall back to the system iOS emojis.

### Previous: v1.4.7

- **Keyboard Flicker Fix (AOSP/Custom ROMs):** Excluded keyboard apps (SwiftKey, Gboard) from internal font replacement. This stops the keyboard from crashing when opening the emoji panel to reply to an Instagram Story.

### Previous: v1.4.6

- **HyperOS Instagram Stories Crash Fix:** Changed permissions of `FacebookEmoji.ttf` to `644` to prevent an unhandled permission exception during Instagram's font validation checks.
- **Meta Emoji Watcher Daemon:** Added an ultra-lightweight background daemon to `service.sh` that actively watches for Instagram's attempts to revert the iOS emojis and silently restores them.

### Previous: v1.4.5

- **Stories Keyboard Crash Fix:** Changed the SELinux context of the Instagram emoji font from `app_data_file` to `system_file`. This allows third-party keyboards (like SwiftKey/Gboard) to read the font when passed by the Instagram Stories editor, preventing the keyboard from crashing and flickering.
- **HyperOS/Dual Apps Support:** Scans all user profiles (`/data/user/*`) to ensure Instagram and other Meta apps in Dual Apps have their emojis replaced correctly.
- **Messenger font block:** Blocks the font download directory (`files/fonts`) for Messenger across all user profiles (`/data/user/*`) to prevent silent redownloads.
- **Crash Fix:** Removed `chattr +i` (immutable flag) from emoji files to prevent Instagram from crashing.

---

## 👏 Credits

| Contributor | Contribution |
| :--- | :--- |
| [**topjohnwu**](https://github.com/topjohnwu) | Creator of Magisk |
| [**tiann**](https://github.com/tiann) | Creator of KernelSU |
| [**TheGabrielHoward**](https://github.com/TheGabrielHoward/IOS-sounds/tree/master) | Original iOS sounds and module inspiration |
| [**dtingley11**](https://github.com/dtingley11/KernelSU-iOS-Emoji) | OEM font replacement code |

---

<p align="center">
  <b>Sentinel Data Solutions</b> | <i>Mobile Experience Engineering</i><br/>
  <b>Developed by Zeca</b>
</p>

<p align="center">
  ⭐ If this module improved your Android experience, consider giving the repo a star!
</p>
