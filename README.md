<h1 align="center">Cull</h1>

<p align="center">
  <b>Free up disk space fast.</b><br>
  Point Cull at a folder, flip through every file, mark each <b>Keep</b> or
  <b>Delete</b> — nothing leaves your disk until you say so.
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/desktop-Windows%20%C2%B7%20macOS%20%C2%B7%20Linux-3A6EA5">
  <img alt="flutter" src="https://img.shields.io/badge/Flutter-3.47-3A6EA5">
</p>

---

## The point

That folder of downloads, screen recordings, camera dumps and half-finished
projects — you know most of it can go, but deleting it means opening each file,
checking, `Del`, confirm, repeat. Cull collapses that loop:

1. **Open a directory.** It shows as a tree you can expand.
2. **Look at each file** in the built-in viewer — image, video (auto-plays),
   audio, PDF, comic book, text, anything.
3. **Mark it** with one key: `D` delete, `S` keep, `Enter` skip to the next.
4. **Commit** once at the end — Cull lists everything marked and deletes it in
   one confirmed pass.

Marking is just a flag. You can change your mind about anything until you hit
*Delete marked files*. Mark a folder and every file inside it inherits the mark.

## Features

- **Expandable directory tree** — expand the folders you care about, leave the
  rest collapsed. Mark a folder → all its files and subfolders are marked too.
- **Previews for everything**
  - Images: JPEG/PNG/GIF/WebP and dozens more (TIFF, ICO, PSD… via a software
    decoder). HEIC/AVIF/RAW show file details.
  - Video & audio: anything ffmpeg can play, via [media_kit]. **Auto-plays.**
  - **Scrub mode** (`V`): skims a long video — play a few seconds, jump ahead,
    repeat. Tunable in *View ▸ Scrub settings…*
  - PDF ([pdfrx]), comic books (`.cbz` / `.cbt` page reader), text (300+
    extensions plus `Dockerfile`, `.gitignore`, …), and a hex fallback.
- **Keyboard-driven triage** — `D` / `S` / `Enter` mark-and-advance across the
  whole visible tree.
- **Safe by default** — every file starts *Keep*. Deletion is a single explicit
  step with a full preview list. A marked parent folder is removed with its
  contents; a locked file is reported, not skipped silently.
- **Windows / macOS / Linux**, one codebase.

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `D` | Mark the viewed file **Delete**, go to next |
| `S` | Mark **Keep**, go to next |
| `Enter` | Next file, no change |
| `V` | Toggle **scrub mode** (video/audio) |
| `Ctrl`/`Cmd` `+O` | Open a directory |
| `Ctrl`/`Cmd` `+Shift` `+D` | Delete marked files… |
| `←` `→` / `PgUp` `PgDn` | Comic reader: previous / next page |

## Install

Grab the one file for your platform from the
[latest release](../../releases/latest):

| Windows | `Cull-*-portable.exe` — double-click |
| macOS | `Cull-*-macos-*.dmg` — open, drag to Applications |
| Linux | `Cull-*-linux-x64.AppImage` — `chmod +x`, run |

Builds are **unsigned**: Windows SmartScreen → *More info ▸ Run anyway*;
macOS → right-click ▸ *Open*.

## Build from source

```bash
flutter pub get
dart run build_runner build      # Riverpod codegen
flutter run -d windows           # or -d macos / -d linux
```

Requires the Flutter 3.47+ stable SDK and the desktop toolchain for your OS
(`docs/SETUP.md`). Packaging: `docs/RELEASING.md`.

## How it decides nothing

Cull never guesses. It shows you the file and you make the call. The only
automatic behaviour is *cascading a folder's mark to its contents* — and that,
too, you can override file by file before committing.

[media_kit]: https://pub.dev/packages/media_kit
[pdfrx]: https://pub.dev/packages/pdfrx
