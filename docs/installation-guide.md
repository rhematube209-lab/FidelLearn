# 📱 💻 FidelLearn Installation & Deployment Guide

This guide explains how to install and run **FidelLearn** across mobile phones (Android, iOS) and desktop computers (Windows).

---

## 1. 🖥️ Installing on Windows Desktop

### Method A: 1-Click Desktop Launcher & Shortcut
We provide a turnkey PowerShell setup script in the project repository:
1. Open PowerShell or command prompt in the project root:
   ```powershell
   .\tools\Install-FidelLearn-Desktop.ps1
   ```
   Or double-click `run_desktop.bat`.
2. This script:
   - Compiles and bundles the standalone FidelLearn Windows application (`fidel_learn.exe`).
   - Copies it to `%LOCALAPPDATA%\Programs\FidelLearn`.
   - Creates a **Desktop Shortcut** (`FidelLearn.lnk`) and a **Start Menu entry**.
   - Launches the app immediately.

### Method B: Development / Direct Run
Run the Windows application directly with Flutter:
```powershell
flutter run -d windows
```

### Method C: Standalone Distribution Folder
To distribute to offline desktop machines without Flutter installed:
```powershell
flutter build windows --release
```
Copy the resulting folder `build\windows\x64\runner\Release\` to any USB flash drive or target Windows PC and run `fidel_learn.exe`.

---

## 2. 📱 Installing on Android Phone

### Method A: Direct Release APK Installation
1. Build the release APK:
   ```powershell
   flutter build apk --release
   ```
2. Locate the generated APK at:
   ```text
   build/app/outputs/flutter-apk/app-release.apk
   ```
3. Transfer `app-release.apk` to any Android phone via USB, Telegram, Google Drive, or Bluetooth, and tap to install.

### Method B: Connecting Phone via USB (Debug / Direct Install)
1. Enable **Developer Options** and **USB Debugging** on the Android phone.
2. Connect the phone to the computer via USB.
3. Verify connection:
   ```powershell
   flutter devices
   ```
4. Install and run directly:
   ```powershell
   flutter run -d android
   ```

---

## 3. 🌐 Installing on Any Smartphone (Android & iPhone / iOS) via PWA

FidelLearn is fully configured as a **Progressive Web App (PWA)** with offline caching:
1. Open the hosted web application URL (e.g. on Chrome, Safari, Edge, or Samsung Internet).
2. **On Android (Chrome / Edge)**:
   - Tap the three-dot menu `⋮` $\rightarrow$ Tap **"Install app"** or **"Add to Home screen"**.
3. **On iPhone (Safari)**:
   - Tap the Share button `⎋` $\rightarrow$ Tap **"Add to Home Screen"**.
4. The FidelLearn icon will appear directly on the phone's home screen, launching full-screen without browser address bars and operating offline.

---

## 4. 🛠️ Platform Verification Checklist

| Platform | Install Target | Offline Support | Vector Diagrams | Step-by-Step Solutions |
| :--- | :--- | :---: | :---: | :---: |
| **Windows Desktop** | `fidel_learn.exe` / Desktop Shortcut | ✅ Drift SQLite | ✅ Interactive SVG | ✅ Verified |
| **Android Phone** | `app-release.apk` | ✅ Drift SQLite | ✅ Interactive SVG | ✅ Verified |
| **PWA Mobile / Web** | Home Screen Web App | ✅ IndexedDB Cache | ✅ Interactive SVG | ✅ Verified |
