# Platform support

Cull's job is to browse **arbitrary directories anywhere on disk** and
**permanently delete** files. That premise decides which platforms it can serve.

## Matrix

| Platform | Status | Notes |
|----------|--------|-------|
| **Windows** | ✅ supported, verified | Primary dev target. Builds and runs. |
| **macOS** | ✅ supported, **build unverified** | `macos/` folder generated. App Sandbox **disabled** (see below). Not built on this Windows dev machine. |
| **Linux** | ✅ supported, **build unverified** | `linux/` folder generated. Needs `libmpv` on the target system for `media_kit`. GTK file chooser via `file_selector_linux`. |
| **Web** | ❌ out of scope | Won't compile: `dart:io` imported directly in the data layer and every viewer. No real filesystem delete on web (File System Access API is Chromium-only and has no recursive delete). |
| **Android** | ❌ out of scope | `file_selector` returns a SAF `content://` URI, not a path — incompatible with `dart:io` `Directory`. Scoped storage (API 29+) blocks raw paths. Deleting non-owned files needs the `RecoverableSecurityException` flow. Would require a whole SAF `FileSource` backend + permissions + responsive layout. |
| **iOS** | ❌ infeasible | The app is sandboxed to its own container. Browsing or deleting files elsewhere on the device **is not possible by design**. A reduced "import a folder, triage copies" mode would be a different product. |

## macOS: why the sandbox is off

The default Flutter macOS template ships with `com.apple.security.app-sandbox`
= `true`. Under the sandbox a process can only touch paths the user explicitly
picked, for the current session. That breaks:

- opening a folder in one session and having marks still valid next launch,
- any path outside the picked tree,
- the general "point it at anything" expectation.

So `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` set
`app-sandbox` to `false`.

**Consequence:** this build cannot ship on the Mac App Store. Direct
distribution (notarized `.dmg`, Homebrew cask) is unaffected.

**If you want MAS later:** set `app-sandbox` back to `true` and add

```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

Browsing is then limited to folders the user picks and their subtrees, and
you'll want to persist security-scoped bookmarks to keep access across launches
(`file_selector` doesn't do this — you'd add it).

## The seam

All filesystem access goes through the `FileSource` interface (`lib/data/fs/`)
and marks through the `MarkStore` interface (`lib/data/marks/`). If Android ever
comes into scope, a `SafFileSource` + a `content://`-aware `MarkStore` slot in
there without touching feature code. The viewer widgets currently read files
directly via `dart:io` and would also need a bytes-oriented abstraction.
