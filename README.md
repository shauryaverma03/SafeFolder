# 🔒 Safe Folder

A production-grade iOS application for securely managing files and folders with password protection and biometric authentication.

---

## 📱 Overview

Safe Folder is a privacy-first file management app that lets you organize photos, videos, documents, and other files into folders — with the option to lock sensitive folders behind a password or Face ID/Touch ID authentication.

### Key Highlights
- **Military-grade security**: SHA-256 password hashing stored in iOS Keychain
- **Biometric authentication**: Face ID & Touch ID support
- **Auto-lock protection**: 15-second inactivity timeout for secure folders
- **Modern UI**: Dark navy theme with electric blue accents, smooth animations
- **Full file management**: Import from Camera, Photo Library, or Files app

---

## 🏗 Architecture

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
┌─────────────────────────────────────────────┐
│                    Views                     │
│  (ViewControllers + Cells)                  │
│  - Handles UI rendering & user interaction  │
│  - Delegates actions to ViewModels          │
└──────────────────┬──────────────────────────┘
                   │ Delegate/Callback
┌──────────────────▼──────────────────────────┐
│                ViewModels                    │
│  - Business logic & state management        │
│  - Data transformation for display          │
│  - Communicates with Utility managers       │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│            Models + Utilities               │
│  - Data models (Folder, FileItem)           │
│  - Keychain, Biometric, FileStorage mgrs    │
│  - Codable persistence (UserDefaults)       │
└─────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
SafeFolder/
├── App/
│   ├── AppDelegate.swift          # App lifecycle, privacy overlay
│   └── AppTheme.swift             # Design system (colors, fonts, layout)
├── Models/
│   ├── Folder.swift               # Folder data model
│   └── FileItem.swift             # File item data model
├── ViewModels/
│   ├── FolderListViewModel.swift  # Home screen business logic
│   └── FolderDetailViewModel.swift # File management + auto-lock
├── Views/
│   ├── FolderListViewController.swift   # Home (folder grid)
│   ├── FolderDetailViewController.swift # File grid + file picker
│   ├── CreateFolderViewController.swift # Create folder bottom sheet
│   ├── AuthViewController.swift         # Password/biometric auth
│   └── Cells/
│       ├── FolderCell.swift       # Folder card cell
│       └── FileCell.swift         # File grid cell
├── Utilities/
│   ├── KeychainManager.swift      # Secure password storage
│   ├── BiometricManager.swift     # Face ID / Touch ID
│   ├── FileStorageManager.swift   # FileManager operations
│   └── HashingUtility.swift       # SHA-256 hashing
└── Resources/
    ├── Assets.xcassets            # App icons & colors
    ├── LaunchScreen.storyboard    # Launch screen
    └── Info.plist                 # Permissions & config
```

---

## 🔐 Security Approach

### Password Security
1. Passwords are **never stored in plain text**
2. All passwords are hashed using **SHA-256** (via CryptoKit) before storage
3. Hashed passwords are stored in the **iOS Keychain** (not UserDefaults)
4. Keychain items are set to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

### Biometric Authentication
- Uses **LocalAuthentication** framework (LAContext)
- Supports **Face ID**, **Touch ID**, and **Optic ID**
- Graceful fallback when biometrics are unavailable
- Settings redirect when permissions aren't granted

### Auto-Lock
- Secure folders auto-lock after **15 seconds** of inactivity
- Visual countdown toast warns users before locking ("Locking in 3...2...1")
- Timer resets on any touch, scroll, or file operation
- App background → immediate lock + blur privacy overlay

### App Lifecycle Protection
- **Background**: Blur overlay hides all content instantly
- **Killed while open**: Secure folder locks on next launch
- **Foreground return**: Requires re-authentication

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📂 Folder Management | Create, delete, secure/unsecure folders |
| 🔒 Password Protection | SHA-256 hashed, Keychain-stored passwords |
| 👆 Biometric Auth | Face ID / Touch ID with fallback |
| ⏱ Auto-Lock | 15s inactivity timeout with countdown |
| 📸 Camera Import | Capture photos directly into folders |
| 🖼 Photo Library | Import photos and videos via PHPicker |
| 📄 Document Import | Import PDFs, docs via UIDocumentPicker |
| 👁 File Preview | QuickLook for docs, full-screen for images |
| 🎨 Dark/Light Mode | Full dynamic color support |
| 📱 Context Menus | Long-press for folder operations |
| ✨ Animations | Spring animations, haptic feedback |
| 🛡 Privacy Overlay | Blur screen on app switch |

---

## 🚀 How to Run

### Requirements
- **Xcode 15.0+**
- **iOS 15.0+** deployment target
- **macOS Ventura+** (for Xcode 15)
- Physical device recommended (for Camera & Biometrics)

### Steps

1. **Clone or download** the project
2. **Open** `SafeFolder.xcodeproj` in Xcode
3. **Select** your development team under Signing & Capabilities
4. **Choose** a simulator or connected device
5. **Build & Run** (⌘R)

### Permissions
The app requests these permissions (configured in Info.plist):
- 📷 **Camera** — for capturing photos
- 🖼 **Photo Library** — for importing photos/videos
- 👤 **Face ID** — for biometric authentication

---

## 🎨 Design

- **Color Scheme**: Deep navy background with electric blue (#4078FF) → purple (#8C4DFF) gradient accents
- **Typography**: SF Pro (system font) with clear weight hierarchy
- **Cards**: Rounded corners (16pt), soft shadows, subtle gradients
- **Animations**: Spring physics for modals, staggered cell entrances
- **Haptics**: Impact feedback on actions, notification feedback on auth

---

## 📸 Screenshots

> *Screenshots coming soon — run the app to see the full experience!*

| Home Screen | Create Folder | Secure Folder Auth |
|:-----------:|:-------------:|:-----------------:|
| Folder grid with cards | Bottom sheet modal | Password / Face ID |

| File Grid | Image Preview | Auto-Lock Toast |
|:---------:|:-------------:|:---------------:|
| 3-column grid | Pinch-to-zoom | Countdown warning |

---

## 🛠 Tech Stack

| Technology | Purpose |
|-----------|---------|
| Swift 5.9+ | Language |
| UIKit | User interface (programmatic) |
| CryptoKit | SHA-256 password hashing |
| LocalAuthentication | Face ID / Touch ID |
| Security (Keychain) | Secure password storage |
| FileManager | File system operations |
| PhotosUI (PHPicker) | Photo library access |
| QuickLook | Document/PDF preview |
| UserDefaults + Codable | Metadata persistence |

---

## 📋 Edge Cases Handled

- ✅ Biometric not available → fallback to password
- ✅ Wrong password → error with retry (max 5 attempts, 30s lockout)
- ✅ Empty folder → custom empty state UI
- ✅ Duplicate file names → auto-rename with suffix
- ✅ App killed while folder open → locks on next launch
- ✅ Storage full → appropriate error message
- ✅ Face ID permission denied → Settings redirect prompt

---

## 📄 License

This project is for educational and personal use.
