import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../scrub_mode_controller.dart';
import '../viewer_key_handler.dart';

/// Plays video and audio via media_kit. **Auto-plays on open** (both video and
/// audio) so triage is hands-free. Owns one [Player] for as long as the
/// viewer keeps showing media files back to back (see the shared key in
/// `bodyForKind`) — stepping to another media file reopens the same player
/// (debounced, see [_openDelay]) instead of constructing a new native player
/// per file, which is expensive enough to bog down rapid triage. The player
/// is only disposed when the widget actually unmounts (selection leaves media
/// entirely) — a file the app still has open cannot be deleted on Windows, so
/// disposing/reopening always fully lets go of the outgoing file first.
///
/// Scrub mode (toggled globally via [scrubModeProvider]): play a short window,
/// jump forward a fraction of the duration, repeat — a fast skim for triage.
class MediaView extends ConsumerStatefulWidget {
  const MediaView({required this.path, required this.audioOnly, super.key});

  final String path;
  final bool audioOnly;

  @override
  ConsumerState<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends ConsumerState<MediaView> {
  static const _seekStep = Duration(seconds: 10);

  /// How long a file has to stay selected before it's actually opened. Since
  /// [MediaView] is reused across video/audio files (see [bodyForKind]),
  /// without this a held arrow/D/S key stepping through many files back to
  /// back would fire a real `Player.open()` — probing the file, spinning up
  /// hardware decode — for every file passed over, not just the one landed
  /// on.
  static const _openDelay = Duration(milliseconds: 150);

  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  StreamSubscription<Duration>? _posSub;
  Timer? _openDebounce;
  Duration _segmentStart = Duration.zero;
  bool _seeking = false;

  @override
  void initState() {
    super.initState();
    _open();
    _posSub = _player.stream.position.listen(_onPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(viewerKeyHandlersProvider.notifier)
          .register(
            step: _step,
            jump: _jump,
            toggle: () => _player.playOrPause(),
          );
    });
  }

  /// Left/Right, PageUp/PageDown → skip the playhead by [_seekStep].
  void _step({required bool forward}) {
    final dur = _player.state.duration;
    var target = _player.state.position + (forward ? _seekStep : -_seekStep);
    if (target < Duration.zero) target = Duration.zero;
    if (dur > Duration.zero && target > dur) target = dur;
    _segmentStart = target; // keep scrub mode advancing from here
    _player.seek(target);
  }

  /// Home/End → jump to the start / near the end.
  void _jump({required bool toEnd}) {
    final dur = _player.state.duration;
    final target = toEnd && dur > const Duration(seconds: 2)
        ? dur - const Duration(seconds: 1)
        : Duration.zero;
    _segmentStart = target;
    _player.seek(target);
  }

  @override
  void didUpdateWidget(MediaView old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _segmentStart = Duration.zero;
      // Stop the outgoing file immediately so stepping through several files
      // doesn't stack audio/decoding while we wait to see if the selection
      // settles; the actual open is debounced below.
      _player.pause();
      _openDebounce?.cancel();
      _openDebounce = Timer(_openDelay, _open);
    }
  }

  Future<void> _open() async {
    // Auto-play video and audio on open.
    await _player.open(Media(widget.path));
    // Honour scrub mode if it was already on when this file opened.
    if (mounted && ref.read(scrubModeProvider)) _setScrub(true);
  }

  void _setScrub(bool on) {
    if (on) {
      _segmentStart = _player.state.position;
      _player.play();
    } else {
      _player.pause();
    }
  }

  void _onPosition(Duration pos) {
    if (!ref.read(scrubModeProvider) || _seeking) return;

    final settings = ref.read(scrubSettingsControllerProvider);
    if (pos - _segmentStart < settings.playWindow) return;

    final dur = _player.state.duration;
    if (dur <= Duration.zero) return;

    var target = pos + dur * settings.skipFraction;
    if (target >= dur - settings.playWindow) target = Duration.zero;
    _segmentStart = target;

    _seeking = true;
    _player.seek(target).whenComplete(() => _seeking = false);
  }

  @override
  void deactivate() {
    // The selection has moved off this file. `Player.dispose()` (in [dispose],
    // one frame later) is async and can leave sound trailing, so silence it
    // now — stepping through the tree with Up/Down must not stack audio.
    _player.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _openDebounce?.cancel();
    ref.read(viewerKeyHandlersProvider.notifier).clear();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scrubModeProvider, (_, on) => _setScrub(on));

    if (widget.audioOnly) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audiotrack, size: 96),
          const SizedBox(height: 16),
          // The Video widget still renders media_kit's transport controls for
          // an audio-only source.
          SizedBox(height: 80, width: 480, child: _video()),
        ],
      );
    }
    return _video();
  }

  /// [Video] tuned for triage:
  /// - `playAndPauseOnTap` — a click on the video body (not the seek bar)
  ///   toggles playback; a double-click still enters fullscreen.
  /// - `keyboardShortcuts: {}` — media_kit's controls otherwise bind the arrow
  ///   keys (Up/Down = volume) and space while the video has focus, swallowing
  ///   them before the app's Up/Down navigation and `stepViewer` seek can run.
  ///   The app handles all of those; space is wired through
  ///   [ViewerKeyHandlers.toggle].
  Widget _video() => MaterialDesktopVideoControlsTheme(
    normal: kDefaultMaterialDesktopVideoControlsThemeData.copyWith(
      playAndPauseOnTap: true,
      keyboardShortcuts: const {},
    ),
    fullscreen: kDefaultMaterialDesktopVideoControlsThemeDataFullscreen
        .copyWith(playAndPauseOnTap: true, keyboardShortcuts: const {}),
    child: Video(controller: _controller),
  );
}
