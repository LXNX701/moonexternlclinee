# UPLOAD TO GITHUB

## Quick Steps

### 1. Create GitHub Token
- Go to: https://github.com/settings/tokens
- Click "Generate new token (classic)"
- Select scopes: `repo`, `workflow`
- Copy the generated token

### 2. Run the Upload Script
Open PowerShell in this directory and run:

```powershell
.\push-to-github.ps1 -GitHubToken "YOUR_TOKEN_HERE" -RepoName "external-cline"
```

### 3. Or do it manually:

```bash
# Create repo on GitHub first (via website or gh CLI)
# Then:

git remote add origin https://github.com/YOUR_USERNAME/external-cline.git
git branch -M main
git push -u origin main
```

---

## After Uploading

### Setup GitHub Secrets for CI/CD

1. Go to your repository on GitHub
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add:
   - Name: `GOOGLE_SERVICE_INFO_PLIST`
   - Value: Base64-encoded content of your GoogleService-Info.plist

To get the base64 value:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\moonzadax7\Downloads\EXTERNAL\EXTERNAL\ThreeOneOSFive\GoogleService-Info.plist"))
```

### Firebase Setup (Required)

1. Go to https://console.firebase.google.com/
2. Create project: `moonexternalios`
3. Add iOS app with bundle ID: `com.dts.external.ios.app`
4. Download `GoogleService-Info.plist`
5. Place it in `ThreeOneOSFive/GoogleService-Info.plist`
6. Enable **Email/Password** and **Anonymous** authentication

---

## Project Structure

```
external-cline/
├── ThreeOneOSFive/
│   ├── App.swift              # Main app (Welcome → Login → MoonPlace)
│   ├── Views/
│   │   ├── MoonWelcomeView.swift
│   │   ├── MoonLoginView.swift
│   │   ├── MoonPlaceView.swift
│   │   ├── PatchModeView.swift
│   │   └── ...
│   ├── Helpers/
│   │   ├── MoonAuthManager.swift  # Firebase Auth
│   │   ├── DevicePatchService.swift # Patch/Restore
│   │   └── ...
│   ├── kexploit/              # Kernel exploit
│   └── Resources/             # .3105 patches
├── Makefile                   # Theos build config
└── .github/workflows/         # GitHub Actions CI/CD
```

---

## Features

- Firebase Authentication (Email/Password, Anonymous)
- Moon Place UI (Dark/Premium theme)
- V1F Mode (8 patches: CABEZA, CUELLO, DRAG, PECHO - SN & V1)
- V2FX Mode (8 patches: CABEZA, CUELLO, DRAG, PECHO - SN & V2)
- Kernel Exploit support
- File Browser
- GitHub Actions CI/CD

---

## Build Locally

```bash
export THEOS=~/theos
make clean
make package FINALPACKAGE=1
```

---

## Support

For issues, open a GitHub issue in the repository.