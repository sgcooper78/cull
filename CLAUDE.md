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
viewer. A **browsable archive row** (zip/tar, `isBrowsableArchive`) also
expands: its children come from `archiveChildrenProvider` as `FsEntry`s with
`!/` paths (`data/archives/archive_entry.dart`), and `treeRows` recurses into
them with `archived: true`. `TreeTile` mark toggle: file → `setMark`;
**folder/archive-folder → `markAllUnder(path, m, includeRoot: true)`** (which
detects `!/` paths and walks the archive's own listing). "All delete/All safe"
bulk buttons act on the whole tree (root).

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
- **comic** — `ComicView` pages through `.cbz` (zip) / `.cbt` (tar); Left/Right / PageUp-Down / Home-End (via `ViewerKeyHandlers`, see keyboard notes); natural-sorted pages. `.cbr` (RAR) / `.cb7` (7z) show a "needs external extractor" message — no pure-Dart decoder.
- **text** — `TextView` (huge extension table + well-known names like `Dockerfile`, `.gitignore`).
- **archive** — `ArchiveView` zip entry list (fallback for a selected archive; the tree also expands zip/tar inline — see below). **other** — `HexView`.
- **archive member** — a file inside an expanded archive: `_ArchiveEntryBody` extracts it to a temp file (`archiveEntryFileProvider`, sha1-named cache under the OS temp dir) then hands the real path to the normal per-kind viewer via `bodyForKind`.

**Archives as directories.** `data/archives/` is the seam: `ArchiveReader` /
`ArchiveWriter` interfaces, `ArchiveResult` sealed type (data/ never throws),
`archiveFormatOf` + `sniffArchiveFormat` (magic bytes). `PackageArchiveReader` /
`PackageArchiveWriter` do zip + tar in pure Dart on a background isolate;
`LibarchiveReader` / `LibarchiveWriter` (hand-written `dart:ffi` binding, no
ffigen) are wired for 7z/RAR but **dormant** — no native lib is vendored, so
they return `nativeBackendMissing` and 7z/RAR stay leaves. `CompositeArchive*`
routes. In the tree, a browsable archive (`isBrowsableArchive` — zip/tar, not
comics) expands like a folder; children come from `archiveChildrenProvider` as
`FsEntry`s whose paths carry the `!/` separator (`data/archives/archive_entry.dart`
— `splitArchivePath` / `rootArchiveOf` / `joinArchivePath`). Selection, marks,
and the triage walk treat `!/` rows like any other.

`.ts` is classified **video** (MPEG-TS), not TypeScript — deliberate for a media tool.

**Triage flow (keyboard):** `D` = mark viewed file delete + advance, `S` = mark
keep + advance, `Enter` = advance without marking (files only), `V` = toggle
**scrub mode** (media only). `Ctrl/Cmd+O` open dir, `Ctrl/Cmd+Shift+D` commit
deletions. `triage_actions.visibleFiles` = every file row currently visible in
the tree, top to bottom — so "next" walks **across folders** you've expanded.

**Arrow keys** (`triage_actions`, bound in `home_shell`'s `CallbackShortcuts`):
`Up`/`Down` = `moveSelection` — walk every visible row, folders included (Down
from nothing → first row, Up from nothing → last). `Left`/`Right` +
`PageUp`/`PageDown` = `stepViewer`, `Home`/`End` = `jumpViewer`: these call
whatever the mounted viewer registered in `viewerKeyHandlersProvider`
(`ComicView` → turn page, `MediaView` → seek ±10s / jump to start/end),
registered post-frame in `initState`, cleared in `dispose`. With no handler,
`stepViewer` expands/collapses a selected folder. The registry (not focus
routing) is used because media_kit's `Video` and pdfrx install focus nodes that
would otherwise swallow the keys.

**Scrub mode is tunable** — View ▸ Scrub settings… (`ScrubSettings`: `playSeconds`
1–30, `skipPercent` 5–50 = "~100/skipPercent previews per file"). Persisted to
`settings.json` in the app-support dir via `SettingsStore` (same interface
pattern as `MarkStore`); changes apply live to playing media.

**Resume.** Delete marks persist by absolute path in `marks.json` (absent =
safe — only delete is written). On top of that, `SettingsStore` has a `"resume"`
key (`{root: lastFilePath}`); `features/browser/resume.dart` `rememberResume`
records the viewed file per root as you move, and `restoreResume` (fired from
`home_shell`'s `ref.listen(browseProvider)`) expands the tree down to that file
and selects it when the directory is reopened. Archive-member selections and
missing files are skipped.

**Space to free.** `deletionStatsControllerProvider`
(`features/triage/deletion_stats.dart`) tallies marked files/folders + summed
file bytes (one cached `stat` per path; archive-member marks counted but not
sized). `BrowserPanel`'s `_MarkedSummary` shows it live as a tappable red bar
above the tree; the confirm dialog shows "Frees about X".

`flutter analyze` clean, **118 tests green**, `flutter build windows --debug`
produces `cull.exe`, which launches and runs. `macos/` + `linux/` folders
generated (macOS App Sandbox **disabled** — see `macos/Runner/*.entitlements`);
neither built/tested on this Windows machine.

**App icon:** `assets/branding/cull_logo.svg` master (open ring + one green dot
on a dark tile) → `windows/runner/resources/app_icon.ico`,
`macos/.../AppIcon.appiconset/*.png`, `linux/cull.png`. Regenerate with the
scratchpad `sharp` + `png2icons` script if the SVG changes.

**Not yet done:** thumbnails / `data/thumbs` (empty), magic-byte type detection
for loose files (`sniffArchiveFormat` exists for archives only), a folder's mark
is explicit (last bulk action) not a derived tri-state, resizable sidebar,
responsive/narrow layout, `integration_test/`, Recycle Bin, verifying the
macOS/Linux builds. A watcher per expanded folder — no cap. **Archives:** the
native 7z/RAR backend is scaffolded but no lib is vendored; nested archives
aren't expanded; extracted archive-member temp files aren't evicted; archive
listings aren't watched (invalidated only after a repackage).

**Format limits (no pure-Dart path on desktop):** HEIC/HEIF/AVIF/JXL and camera
RAW images (shown as a metadata card, not pixels); `.cbr` (RAR) / `.cb7` (7z)
comics and `.7z`/`.rar` archives (no working backend — "not installed" card /
left as tree leaves). `.ts` reads as video. Comic pages and archive-member
previews are cached without eviction — a giant `.cbz` grows memory as you read.

**Repackage on delete:** marking a file (or folder) *inside* an expanded zip/tar
and running **Delete marked** rewrites that archive once
(`ArchiveWriter.rewriteWithout` → sibling `*.cull-tmp` → swap over the original)
minus the marked entries; `commitDeletions` groups marks by archive, subsumes
members when the archive file itself is marked, and keeps marks + reports a
failure if the rewrite fails. The confirm dialog warns that archives will be
rebuilt (compression/metadata may change).

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
- **Archives: `archive` — CONFIRMED** for zip/tar (listing, `.cbz`/`.cbt` pages, browse-as-directory, repackage-on-delete). Cannot do RAR / 7z — `data/archives/libarchive/` has a hand-written `dart:ffi` binding for that, plus `ffi` and `crypto` deps, but no shared lib is vendored yet so it stays dormant.
- **PDF: `pdfrx`** (pdfium) — in use, not "locked". Downloads/links pdfium at build time.
- **Extended image decode: `image`** (pure-Dart) — in use for tif/tga/ico/psd/pnm/exr etc.
- **Paths: `path_provider` — CONFIRMED.** App-support/cache directory resolution. Not up for revisiting.
- **Marks / review progress:** JSON sidecar via `path_provider` app-support dir, keyed by absolute path (v1). `MarkStore` is an interface — `JsonFileMarkStore` in prod, `InMemoryMarkStore` (test/support) for widget tests. Move to `drift`/SQLite if the catalog grows large.
- **Delete:** `File.delete()` / `Directory.delete(recursive: true)` via `MarksController.commitDeletions` — marked parent folder subsumes its marked descendants; already-gone paths count as success; locked files surface as failures and keep their mark. Marks *inside* an archive (`!/` paths) are applied by rewriting that archive via `ArchiveWriter.rewriteWithout` instead of `File.delete`. Always behind the confirm dialog in `features/triage/delete_marked.dart`. No Recycle Bin in v1 (revisit later via `win32` `SHFileOperation`).
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
    settings/     ScrubSettings, SortSettings, SettingsStore (settings.json: scrub / sort / resume keys)
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

`cull-lead` is the entry point for anything spanning more than one area —
it breaks the work into subtasks and dispatches them to the right
specialist(s) below. Go straight to a specialist for a task that's clearly
inside one area.

| Agent | Use for |
|-------|---------|
| `cull-lead` | **Manager.** Multi-part/cross-area work — plans, delegates to the specialists below, integrates results |
| `flutter-architect` | Planning features and structural changes (returns a plan, not code) |
| `flutter-ui-builder` | Building/altering feature UI and Riverpod providers under `lib/features/` |
| `riverpod-state-specialist` | Provider design/audit — lifecycle, `keepAlive`, hydrate-from-storage races, codegen hygiene |
| `media-preview-specialist` | The preview pipeline, thumbnails, format detection (`lib/features/viewer/`, `lib/data/thumbs/`) |
| `archive-specialist` | The archive data layer (`lib/data/archives/`) — zip/tar, the dormant 7z/RAR backend, repackage-on-delete |
| `platform-integration` | Filesystem/`FileSource`, delete semantics, method channels, Windows/macOS/Linux runner config |
| `performance-auditor` | CPU/memory pegging, UI-thread freezes, native-resource churn, unthrottled watchers/caches |
| `security-reviewer` | Destructive-op and path-handling safety — the delete path, archive extraction, confirm-dialog gating |
| `flutter-test-writer` | Unit / widget / integration tests |
| `dart-reviewer` | Reviewing a diff before commit |
| `release-manager` | Version bump, git tag, push, and the release CI/packaging scripts |
