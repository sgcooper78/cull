import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'viewer_key_handler.g.dart';

/// Left/Right (and PageUp/PageDown) — "step within the thing on screen".
typedef ViewerStepHandler = void Function({required bool forward});

/// Home/End — "jump to the far end of the thing on screen".
typedef ViewerJumpHandler = void Function({required bool toEnd});

/// Callbacks the currently-mounted viewer registers so the app-global arrow
/// shortcuts can drive it without the key events having to route through the
/// viewer's own focus subtree (media_kit's `Video` and pdfrx both install
/// focus nodes that would otherwise swallow the keys).
///
/// A viewer calls [ViewerKeyHandlers.register] from `initState` (post-frame)
/// and [ViewerKeyHandlers.clear] from `dispose`. Only one viewer is mounted at
/// a time, so last-writer-wins is correct.
typedef ViewerKeyBinding = ({ViewerStepHandler? step, ViewerJumpHandler? jump});

@Riverpod(keepAlive: true)
class ViewerKeyHandlers extends _$ViewerKeyHandlers {
  @override
  ViewerKeyBinding build() => (step: null, jump: null);

  void register({ViewerStepHandler? step, ViewerJumpHandler? jump}) {
    state = (step: step, jump: jump);
  }

  void clear() => state = (step: null, jump: null);
}
