# Dev environment setup (Windows)

Status as of 2026-09-07:

- [x] **Flutter SDK** — 3.47.2 stable installed at `C:\flutter\flutter`, `bin` on user PATH (steps 2–4 below, done).
- [ ] **Visual Studio 2022 + "Desktop development with C++"** — still required for the Windows target (step 1).
- [ ] Android SDK — skipped, not needed for v1.

## 1. Prerequisites — VISUAL STUDIO STILL NEEDED

- **Git for Windows** — installed.
- **Visual Studio 2022** (not VS Code) with the **"Desktop development with C++"**
  workload. **Not yet installed.** Required to build the Windows desktop target;
  `flutter run -d windows` fails without it. Community edition is fine.
  - Installer: <https://visualstudio.microsoft.com/downloads/>
  - In the installer, check "Desktop development with C++", install, reboot.
  - Verify with `flutter doctor` — the "Visual Studio - develop Windows apps" line should go green.

## 2. Install the Flutter SDK — DONE

Installed at `C:\flutter\flutter` (3.47.2 stable). Kept for reference:

Pick one. Avoid paths that need admin rights (no `C:\Program Files`).

**Option A — git clone (easiest to update):**

```powershell
git clone https://github.com/flutter/flutter.git -b stable "$env:USERPROFILE\dev\flutter"
```

**Option B — zip:** download the latest stable Windows zip from
<https://docs.flutter.dev/get-started/install/windows> and extract to
`C:\src\flutter`.

## 3. Add Flutter to PATH

Add `<flutter>\bin` (e.g. `%USERPROFILE%\dev\flutter\bin`) to your **user** `Path`
environment variable, then open a new terminal.

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\dev\flutter\bin",
  "User")
```

## 4. Verify

```powershell
flutter --version
flutter doctor
```

Resolve anything `flutter doctor` flags. For this project you need at minimum:
- `[✓] Flutter`
- `[✓] Windows Version`
- `[✓] Visual Studio - develop Windows apps`

Android/iOS/Chrome checks can stay red for now — v1 is Windows only.

```powershell
flutter config --enable-windows-desktop
```

## 5. (Later) Scaffold the app

Not part of the current scope — the repo is agent-config only right now. When
ready, from the project root:

```powershell
flutter create --project-name cull --org com.<you> --platforms=windows .
flutter run -d windows
```

`flutter create` initializes a git repo and a `.gitignore` automatically.

## Optional

- **VS Code** + the Flutter extension, or **Android Studio** + Flutter plugin, for
  hot reload and debugging from the editor.
