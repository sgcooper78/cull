# CLAUDE.md

## Project: Cull (working name — rename freely)

Desktop Flutter app for **triaging files on disk**. Point it at a directory,
navigate its folders, and give every file **and folder** a mark: `safe` (green ✓,
the default) or `delete` (red ✗). Marking only flags — nothing leaves disk until
**File ▸ Delete marked files…**, which confirms with a full list then permanently
removes (`File.delete` / `Directory.delete(recursive: true)`). Bulk mark reaches
the current folder **plus all subfolders**. **Supported targets: Windows, macOS,
Linux.** Web and mobile are out — the "delete anything on disk" premise is
incompatible with their sandboxes (see `docs/PLATFORMS.md`).

## Status

**v1 built (2026-09-07), desktop-trio.** Two-pane UI: `MenuBar` (File / Mark /
View) + `BrowserPanel` sidebar + `ViewerPanel`.

**Sidebar = expandable directory tree.** `treeRowsProvider` (`tree_controller.dart`)
flattens root + expanded folders depth-first into `List<TreeRow>` (sealed:
`EntryRow` / `LoadingRow` / `ErrorRow`) for a `ListView.builder`. `TreeExpansion`
notifier holds the `Set<String>` of open dir paths; each expanded folder watches
its own `directoryListingProvider(path)` (so N expanded folders = N
`DirectoryWatcher`s). Tap a folder row → expand/collapse; tap a file → open in
viewer. `TreeTile` mark toggle: file → `setMark`; **folder →
`markAllUnder(path, m, includeRoot: true)` — marks the folder and everything
under it**. "All delete/All safe" bulk buttons act on the whole tree (root).

**Sorting** (`SortMenu` in the sidebar header): `SortSettingsController` +
`SortSettings` (`data/settings/sort_settings.dart`: `key` name/size/modified/type,
`ascending`, `foldersFirst`; `.compare(a,b)` is the `List<FsEntry>.sort`
comparator — natural name order, name tiebreak). `treeRowsProvider` sorts each
folder's entries with it. Persisted to `settings.json` `"sort"` key via
`SettingsStore` (same as scrub). Picking the active key flips direction. The
triage walk (`visibleFiles`) follows the sort order.

`ViewerPanel` — metadata header with a `MarkChoice` Delete/Keep segmented
control, body dispatched by `FileKind`:
- **image** — `ImageView` 3-tier: native decoder (jpg/png/gif/webp/bmp…), `image` package CPU decode in an isolate (tif/tga/ico/psd/pnm…), or a "no pure-Dart decoder" card (heic/avif/jxl/RAW).
- **video / audio** — `MediaView` (media_kit / ffmpeg — very broad extension table). **Auto-plays on open** (video and audio); disposing on file-change stops playback so there's no overlap while stepping through the triage flow.
- **pdf** — `PdfView` (`pdfrx` / pdfium). `pdfrxFlutterInitialize()` in `main.dart`.
- **comic** — `ComicView` pages through `.cbz` (zip) / `.cbt` (tar); arrow / PageUp-Down / Home-End; natural-sorted pages. `.cbr` (RAR) / `.cb7` (7z) show a "needs external extractor" message — no pure-Dart decoder.
- **text** — `TextView` (huge extension table + well-known names like `Dockerfile`, `.gitignore`).
- **archive** — `ArchiveView` zip entry list. **other** — `HexView`.

`.ts` is classified **video** (MPEG-TS), not TypeScript — deliberate for a media tool.

**Triage flow (keyboard):** `D` = mark viewed file delete + advance, `S` = mark
keep + advance, `Enter` = advance without marking, `V` = toggle **scrub mode**
(media only). `Ctrl/Cmd+O` open dir, `Ctrl/Cmd+Shift+D` commit deletions.
`triage_actions.visibleFiles` = every file row currently visible in the tree,
top to bottom — so "next" walks **across folders** you've expanded (expand what
you care about, collapse the rest).

**Scrub mode is tunable** — View ▸ Scrub settings… (`ScrubSettings`: `playSeconds`
1–30, `skipPercent` 5–50 = "~100/skipPercent previews per file"). Persisted to
`settings.json` in the app-support dir via `SettingsStore` (same interface
pattern as `MarkStore`); changes apply live to playing media.

`flutter analyze` clean, **72 tests green**, `flutter build windows --debug`
produces `cull.exe`, which launches and runs. `macos/` + `linux/` folders
generated (macOS App Sandbox **disabled** — see `macos/Runner/*.entitlements`);
neither built/tested on this Windows machine. Git repo initialized, first commit
not yet made.

**Not yet done:** thumbnails / `data/thumbs` (empty), magic-byte type detection
(extension-only), a folder's mark is explicit (last bulk action) not a derived
tri-state of its children, resizable sidebar, responsive/narrow layout,
`integration_test/`, Recycle Bin, verifying the macOS/Linux builds. A watcher
per expanded folder — no cap yet.

**Format limits (no pure-Dart path on desktop):** HEIC/HEIF/AVIF/JXL and camera
RAW images (shown as a metadata card, not pixels); `.cbr` (RAR) and `.cb7` (7z)
comics (message telling the user to convert to `.cbz`). `.ts` reads as video.
Comic pages are loaded from the archive on demand and cached per page — a giant
`.cbz` grows memory as you read; eviction is a TODO.

**Toolchain:**
- Flutter **3.47.2 stable** at `C:\flutter\flutter` (Dart 3.13.2 bundled).
- Visual Studio **Community 2026 18.9.2** with C++ desktop workload — `flutter doctor` green. Windows target builds.
- `flutter doctor` clean except Android toolchain (not needed for v1).
- `C:\flutter\flutter\bin` is on the persisted user PATH, but a Claude Code session started before the install won't see it — prepend it per-command or start a fresh session.
- Harmless CMake "CMP0175 / PRE_BUILD" warnings during `build windows` come from the upstream `media_kit_libs_windows_video` plugin — ignore them.
- If `flutter build windows` fails at `INSTALL.vcxproj` with `MSB3073` and no real error, a stray `cull.exe` (from an earlier run) is locking the output — `taskkill /F /IM cull.exe` and rebuild.
- App name is **Cull** (kept). Package name stays `cull`; user-facing titles in `windows/runner/{main.cpp,Runner.rc}`, `linux/runner/my_application.cc`, `macos/Runner/Configs/AppInfo.xcconfig`, and `MaterialApp.title` say "Cull". Bundle id `com.sgcooper.cull` on all three.

## Tech stack (decisions — keep these consistent)

- Flutter **stable** channel, Dart 3+, sound null safety
- **State: Riverpod — CONFIRMED.** Resolved to the **v3 line** (`flutter_riverpod` 3.4.x, `riverpod_annotation` 4.0.x, `riverpod_generator` 4.0.x). `@riverpod` codegen — run `dart run build_runner` after changing annotated providers. Not up for revisiting. (`riverpod_lint`/`custom_lint` skipped for now — version conflict with the v3 line; revisit later.)
- **Routing: `go_router` — CONFIRMED.** Not up for revisiting.
- **Filesystem:** `dart:io` (`File`, `Directory`), `path`. **`watcher` — CONFIRMED** for live directory changes. Not up for revisiting.
- **Images:** `Image.file` + **`photo_view` — CONFIRMED** for zoom/pan. Not up for revisiting. Thumbnails cached in the app-support dir.
- **Video/audio: `media_kit` — CONFIRMED.** With `media_kit_video`, `media_kit_libs_video`. Chosen over `video_player` for real Windows/desktop support. Not up for revisiting.
- **Archives: `archive` — CONFIRMED.** Zip/tar listing + `.cbz`/`.cbt` comic pages. Cannot do RAR / 7z.
- **PDF: `pdfrx`** (pdfium) — in use, not "locked". Downloads/links pdfium at build time.
- **Extended image decode: `image`** (pure-Dart) — in use for tif/tga/ico/psd/pnm/exr etc.
- **Paths: `path_provider` — CONFIRMED.** App-support/cache directory resolution. Not up for revisiting.
- **Marks / review progress:** JSON sidecar via `path_provider` app-support dir, keyed by absolute path (v1). `MarkStore` is an interface — `JsonFileMarkStore` in prod, `InMemoryMarkStore` (test/support) for widget tests. Move to `drift`/SQLite if the catalog grows large.
- **Delete:** `File.delete()` / `Directory.delete(recursive: true)` via `MarksController.commitDeletions` — marked parent folder subsumes its marked descendants; already-gone paths count as success; locked files surface as failures and keep their mark. Always behind the confirm dialog in `features/triage/delete_marked.dart`. No Recycle Bin in v1 (revisit later via `win32` `SHFileOperation`).
- **Lints: `flutter_lints` — CONFIRMED.** Baseline rule set. Not up for revisiting.
- **Packaging — one runnable file per platform, nothing else:** `Cull-<v>-portable.exe` (Windows, Enigma Virtual Box), `Cull-<v>-macos-arm64.dmg`, `Cull-<v>-linux-x64.AppImage`. Scripts in `tool\` → `dist\` (gitignored): `build_portable.ps1` (needs Enigma Virtual Box — CI installs it from the vendor URL since the Chocolatey package is checksum-broken; `gen_evb.ps1` builds the `.evb` from real output, no GUI step; fatal if Enigma missing/rejects), `package_macos.sh [arm64|x64]`, `package_linux.sh`. CI: `.github/workflows/release.yml` — matrix (windows / macos-14 / ubuntu) on `v*` tags + `workflow_dispatch`. Tag → `release` job publishes the files; manual run → downloadable workflow artifacts only. **macOS Intel dropped** — those runners queue for ages and GitHub is retiring them; arm64 only. Runners have every toolchain — no local Mac/Linux needed. Full guide `docs/RELEASING.md`.

## Project layout (feature-first)

```
lib/
  main.dart
  app/            app widget, go_router config, theme, top-level providers
  core/           file_kind (ext→FileKind + ImageSupport), formatting, natural_sort
  data/
    fs/           FileSource interface + dart:io backend, directory walking, delete ops
    thumbs/       thumbnail generation + LRU cache
    marks/        Mark, MarkStore interface (JSON sidecar), MarksController
    settings/     ScrubSettings, SortSettings, SettingsStore + settingsStoreProvider (settings.json)
  features/
    browser/      pick + navigate directories, file list/grid
    viewer/       preview: image / video / audio / archive / text / unknown fallback
    triage/       marking UI, keyboard-driven flow, session summary
  services/       platform-facing wrappers (fs, media, packaging)
test/
  unit/           data/ + core/
  widget/         feature UI
integration_test/ end-to-end triage flow
```

**Rules**

- Feature folders own their widgets, providers, and models. Shared code goes in `core/` or `data/`.
- No `dart:io` or raw file ops inside `features/**` widgets — go through `data/` or `services/`.
- Every `Notifier`/controller that opens resources (media_kit players, file handles, directory watchers, focus nodes, stream subscriptions) disposes them. A leaked handle on Windows blocks deletion of that file.
- `data/` returns `Result`-style values; it does not throw across layers. UI surfaces failures — never swallows them.
- Destructive operations (delete) require a confirm dialog and a log entry.

## Platforms

**Supported: Windows, macOS, Linux.** Full `dart:io` directory access, one
`IoFileSource` backend. See `docs/PLATFORMS.md` for the full matrix and the
detailed reasoning.

- **macOS:** App Sandbox is **disabled** in `macos/Runner/DebugProfile.entitlements`
  and `Release.entitlements` — under the sandbox, arbitrary-path browse+delete
  doesn't work. Consequence: no Mac App Store. The files explain the MAS
  alternative (`files.user-selected.read-write` + sandbox on).
- **Linux:** `file_selector_linux` uses the GTK chooser; `media_kit_libs_linux`
  needs `libmpv` present on the target system at runtime.
- **Menu modifier:** `_menuKey` in `home_shell.dart` picks Cmd on macOS, Ctrl
  elsewhere. Triage keys (`D`/`S`/`Enter`/`V`) are unmodified and identical
  across all three.
- **Not built here:** this dev machine is Windows-only; `flutter build macos` /
  `flutter build linux` have never run. Generated, unverified.

**Web / Android / iOS are out of scope** and `dart:io` is imported directly
(`fs_providers.dart`, `mark_store.dart`, `browse_controller.dart`, the viewer
widgets) — the web build will not compile as-is. The `FileSource` / `MarkStore`
interfaces are the seam if that ever changes.

Keep all filesystem access behind the `FileSource` interface in `data/fs/`.

## Commands

| Task | Command |
|------|---------|
| Environment check | `flutter doctor` |
| Install deps | `flutter pub get` |
| Format | `dart format .` |
| Static analysis | `flutter analyze` |
| Tests | `flutter test` |
| Run (Windows) | `flutter run -d windows` |
| Release build | `flutter build windows --release` |
| Codegen (one-shot) | `dart run build_runner build` |
| Codegen (watch) | `dart run build_runner watch` |

Slash commands wrap the common ones: `/check`, `/run`, `/deps`, `/feature`.

## Conventions

- `dart format` (80 col) before every commit. `/check` runs format + analyze + test.
- Prefer `const` constructors. Split large `build` methods. Scope rebuilds with `ref.watch(p.select(...))`.
- Riverpod codegen: annotate with `@riverpod`; run `build_runner` after changes.
- Errors: `data/` returns `Result`; the UI decides how to show a failure.
- Tests: unit for `data/` + `core/`, widget for feature UI, `integration_test/` for the triage flow. Use `FakeFileSource` + `InMemoryMarkStore` (`test/support/`) — never touch real disk in unit/widget tests.
- **`testWidgets` runs in a FakeAsync zone: real file/dir IO and real timers never complete there and hang the isolate (even `--timeout` can't fire).** Widget tests must use all in-memory fakes, and override `directoryListingProvider` family-wide (`directoryListingProvider.overrideWith((ref, _) => Stream.value(entries))`) so the real `DirectoryWatcher` never starts. Fake paths in tests are native-style (`C:\root\...` on Windows) so `path.normalize` is a no-op. Don't render `ViewerPanel`'s `_Body` in a widget test — every viewer does real IO; test `triage_actions.dart` via a `Consumer` that captures `ref` instead.
- Triage keys live in `home_shell.dart`'s `CallbackShortcuts`; the logic is in `features/triage/triage_actions.dart` (`advanceSelection`, `markCurrentAndAdvance`). `currentFolderFiles` reads `directoryListingProvider` for the current folder and drops directories.

## Agents (`.claude/agents/`)

| Agent | Use for |
|-------|---------|
| `flutter-architect` | Planning features and structural changes (returns a plan, not code) |
| `flutter-ui-builder` | Building/altering feature UI and Riverpod providers under `lib/features/` |
| `media-preview-specialist` | The preview pipeline, thumbnails, format detection (`lib/features/viewer/`, `lib/data/thumbs/`) |
| `platform-integration` | Filesystem/`FileSource`, delete semantics, method channels, Windows build, packaging |
| `flutter-test-writer` | Unit / widget / integration tests |
| `dart-reviewer` | Reviewing a diff before commit |
