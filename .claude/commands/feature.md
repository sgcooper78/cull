---
description: Scaffold a new feature folder
argument-hint: "<feature-name>"
---

Scaffold `lib/features/$ARGUMENTS/`, matching the style of existing features:

- `<feature-name>_screen.dart` — a `ConsumerWidget` screen stub
- `<feature-name>_controller.dart` — an `@riverpod` `Notifier` stub
- `widgets/` — with a `.gitkeep`
- `models/` — with a `.gitkeep`

Also create `test/widget/<feature-name>/` and `test/unit/<feature-name>/`.

Wire the new screen into the `go_router` config in `lib/app/`. Then run
`dart run build_runner build` and `flutter analyze`, and report the output.
