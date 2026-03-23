# 🍎 iOS Sounds & Emojis for Android (Pro Magisk Module)

[![Magisk](https://img.shields.io/badge/Root-Magisk-orange?style=for-the-badge)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/Root-KernelSU-green?style=for-the-badge)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/Root-APatch-blue?style=for-the-badge)](https://github.com/bmax121/APatch)

A high-performance system-level modification module that brings the premium iOS auditory and visual experience to any rooted Android device. Built with robustness and compatibility in mind, this module uses intelligent installation scripts to ensure zero-risk deployment.

## 🛠️ Intelligent Installation Engine (`customize.sh`)

Unlike generic sound packs, this module features a sophisticated installation logic that adapts to your device's environment.

### Deployment Logic
```mermaid
graph TD
    Start[Start Install] --> Env[Detect Environment: Magisk/KSU/APatch]
    Env --> AndroidAPI[Check Android API Level]
    
    AndroidAPI -- API 31+ --> ProdPath[Target: /system/product/media/audio]
    AndroidAPI -- API < 31 --> LegacyPath[Mirror: /system/media/audio]
    
    ProdPath --> OEM[Detect OEM: Xiaomi/Samsung/AOSP]
    LegacyPath --> OEM
    
    OEM --> FontRepl[Replace OEM-specific Emoji Fonts]
    FontRepl --> Gboard[Deep Clear Gboard Cache]
    Gboard --> Permissions[Apply SELinux & u:object_r:system_file contexts]
    Permissions --> End[Success]
```

### Key Technical Features

| Feature | Description |
| :--- | :--- |
| **OEM Detection** | Automatically detects and replaces fonts like `MiuiColorEmoji.ttf` or `SamsungColorEmoji.ttf` to ensure emojis work in all apps. |
| **Dual-Path Shield** | Mirrors sound files across `/product` and legacy `/system` paths for maximum ROM compatibility. |
| **SELinux Compliance** | Enforces correct `u:object_r:system_file:s0` contexts, preventing "silent boot" issues common in modern Android versions. |
| **OverlayFS Support** | Integrated support for `magisk_overlayfs` for devices with restricted partitions. |

## 📦 What's Included
- **UI Sounds**: Complete iOS sound set (Lock, Charging, Keyboard Taps, Camera, etc.).
- **Emojis**: Latest iOS emoji set with high-resolution Noto-compatible rendering.
- **Typography**: Apple's **SF Pro Display** fonts integrated into the system font stack.

## 🚀 Installation
1. Download the latest `.zip` release.
2. Flash via **Magisk Manager**, **KernelSU**, or **APatch**.
3. Reboot and enjoy.

---
> [!IMPORTANT]
> This module clears the Gboard cache during installation to force the refresh of the emoji picker. You may need to wait a few seconds on the first keyboard launch.

**Sentinel Data Solutions** | *Mobile Experience Engineering*
**Developed by Zeca**
