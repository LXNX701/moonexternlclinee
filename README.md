# Moon Place - iOS App

A premium iOS application with advanced patching capabilities, Firebase authentication, and a modern dark UI.

## Features

- **Firebase Authentication** - Email/Password, Anonymous, and License Key login
- **Moon Place UI** - Modern dark/premium interface with animations
- **V1F Mode** - 8 patch options (CABEZA, CUELLO, DRAG, PECHO - SN & V1)
- **V2FX Mode** - 8 patch options (CABEZA, CUELLO, DRAG, PECHO - SN & V2)
- **Kernel Exploit** - Full device access with sandbox escape
- **File Browser** - Browse and manage app containers
- **Patch System** - Apply and Restore patches with transaction safety
- **Multi-language** - English, Vietnamese, Simplified Chinese

## Requirements

- iOS 15.0+
- Xcode 16.0+
- Theos (for building)
- macOS (for building)

## Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing
3. Add iOS app with bundle identifier: `com.dts.external.ios.app`
4. Download `GoogleService-Info.plist`
5. Add it to the `ThreeOneOSFive/` directory

### Enable Authentication
1. In Firebase Console, go to Authentication
2. Enable Email/Password provider
3. Enable Anonymous provider (optional)

### Create License Keys (Optional)
License keys follow the format: `MOON-XXXX-XXXX-XXXX`

You can generate these in your Firebase database or use the auth manager's built-in validation.

## Building

### Local Build with Theos

```bash
# Clone the repository
git clone https://github.com/yourusername/moonplace.git
cd moonplace

# Setup Theos (if not already installed)
export THEOS=~/theos

# Build
make clean
make package FINALPACKAGE=1
```

### GitHub Actions

The repository includes a GitHub Actions workflow that automatically builds the IPA on every push to main/master.

To enable Firebase in CI:
1. Go to Repository Settings > Secrets and variables > Actions
2. Add `GOOGLE_SERVICE_INFO_PLIST` with the base64-encoded content of your plist file

```bash
# Encode your plist file
base64 -i GoogleService-Info.plist
```

## Project Structure

```
EXTERNAL/
├── ThreeOneOSFive/
│   ├── App.swift                    # Main app entry with Firebase
│   ├── ContentView.swift            # Original content view
│   ├── Views/
│   │   ├── MoonWelcomeView.swift    # Welcome splash screen
│   │   ├── MoonLoginView.swift      # Login/Register screen
│   │   ├── MoonPlaceView.swift      # Main mode selector
│   │   ├── PatchModeView.swift      # V1F/V2FX patch view
│   │   ├── PatchOptionRow.swift     # Individual patch row
│   │   └── ...                      # Other views
│   ├── Helpers/
│   │   ├── MoonAuthManager.swift    # Firebase auth manager
│   │   ├── DevicePatchService.swift # Patch apply/restore
│   │   ├── PatchProjectStore.swift  # Patch state management
│   │   └── ...                      # Other helpers
│   ├── kexploit/                    # Kernel exploit code
│   └── Resources/                   # App resources & patches
├── BotCompat/                       # Objective-C compatibility layer
├── Makefile                         # Build configuration
└── .github/workflows/               # CI/CD configuration
```

## Architecture

### Authentication Flow
```
Launch → Welcome Screen → Login/Register → Firebase Auth → License Check → Main App
```

### Patch Flow
```
Select Mode (V1F/V2FX) → Select Patch → Apply/Restore → Transaction Receipt
```

### Firebase Integration
- Email/Password authentication
- Anonymous authentication for guests
- License key activation (format: MOON-XXXX-XXXX-XXXX)
- Session persistence

## Important Notes

- **No secrets in code** - Firebase configuration uses GoogleService-Info.plist
- **Bundle ID preserved** - Uses existing `com.dts.external.ios.app`
- **Kernel exploit preserved** - All original functionality maintained
- **Patches preserved** - All .3105 patch files included

## License

This project is for educational and research purposes. Use only on devices you own.

## Credits

- Original 3105 project by YangJiii
- Moon Place UI enhancements
- Firebase integration