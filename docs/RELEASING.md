# Releasing

Supported targets: **Windows, macOS (arm64 + x64), Linux (x64)**. Web/Android/iOS
are out of scope (`docs/PLATFORMS.md`).

## Automated — GitHub Actions

`.github/workflows/release.yml` runs on every `v*` tag (and manually via
**Actions → Release → Run workflow**). A matrix builds each platform, then a
`release` job collects everything and publishes one GitHub Release.

To cut a release:

```
# bump version: in pubspec.yaml first, e.g. 1.1.0+2
git tag v1.1.0
git push origin v1.1.0
```

Per-platform, the workflow: sets up Flutter 3.47.2 → `pub get` → `build_runner`
→ (Linux only) `analyze` + `test` → builds + packages → uploads. On a tag it also
attaches everything to the Release.

### ⚠ macOS and Linux builds are UNVERIFIED

They have never run on the dev machine. The first CI run is the real test.
Likely first-time fixes:

- **macOS:** `pdfrx` / `media_kit` may need a higher deployment target. If
  `flutter build macos` fails on that, bump `platform :osx, '10.15'` (or `'11.0'`)
  in `macos/Podfile` and `MACOSX_DEPLOYMENT_TARGET` in
  `macos/Runner.xcodeproj/project.pbxproj`.
- **Linux:** missing `-dev` package → add it to the "Linux build deps" step.
- `fail-fast: false` means one platform failing doesn't block the others, so a
  tag can still produce a partial release; re-run after fixing.

## What each platform ships

**One runnable file per platform. No zips, no tarballs.**

| Platform | File | Notes |
|----------|------|-------|
| Windows | `Cull-<ver>-portable.exe` | Enigma Virtual Box single exe. |
| macOS | `Cull-<ver>-macos-{arm64,x64}.dmg` | Single-file form of the `.app`. `macos-14` (arm64) + `macos-13` (Intel). |
| Linux | `Cull-<ver>-linux-x64.AppImage` | Self-contained executable. |

All unsigned — see the Release body for the per-OS "unknown publisher / damaged"
click-through.

## Local packaging

```powershell
powershell -File tool\build_portable.ps1        # Windows  -> dist\Cull-<ver>-portable.exe
```
```bash
bash tool/package_macos.sh [arm64|x64]          # macOS    -> dist/
bash tool/package_linux.sh                      # Linux    -> dist/
```

`dist/` is gitignored.

### Windows single .exe

`build_portable.ps1` **requires** Enigma Virtual Box — it produces only the
single exe (no folder, no zip). Install it once:

```
# vendor installer (the Chocolatey package is currently broken — stale checksum):
#   https://enigmaprotector.com/assets/files/enigmavb.exe  ->  /VERYSILENT install
choco install enigmavirtualbox     # try this first; falls back to the URL above
```

CI (`release.yml`) installs it from the vendor URL directly for the same reason.

Then the script does everything — `tool\gen_evb.ps1` generates the `.evb`
project from the real build output (no drift, no GUI step).

If `enigmavbconsole` rejects the generated project on your Enigma version, the
script fails. Fix: open `dist\cull.evb` in the Enigma GUI, **Add → Add Folder
Recursive** on `build\windows\x64\runner\Release`, **Save**, **Process**, then
port any differing tags back into `tool\gen_evb.ps1`. (`flutter build windows
--release` still gives you the runnable folder in the meantime.)

### Linux AppImage locally

`package_linux.sh` downloads `appimagetool` v13 into `build/` and runs it with
`APPIMAGE_EXTRACT_AND_RUN=1` (no FUSE needed). Needs `libgtk-3-dev`, `libmpv-dev`,
`ninja-build`; `imagemagick` for the placeholder icon (optional).

## Smoke test

Run each artifact on a **clean machine / fresh user profile** — the point is that
no dev tools are assumed. Open an image, a video (auto-plays), a PDF, a `.cbz`.

## Signing (later)

Unsigned is fine for a personal GitHub release. When it matters:
`signtool` (Windows), `codesign` + `notarytool` (macOS). Linux AppImages are
typically GPG-signed with a `.zsync`/`.sig` alongside.
