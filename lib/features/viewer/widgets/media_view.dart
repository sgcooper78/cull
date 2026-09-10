import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../scrub_mode_controller.dart';
import '../viewer_key_handler.dart';

/// Plays video and audio via media_kit. **Auto-plays on open** (both video and
/// audio) so triage is hands-free. Owns a [Player] and disposes it when the
/// widget unmounts or the path changes — a file the app still has open cannot
/// be deleted on Windows, and disposing stops playback before the next file.
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

  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  StreamSubscription<Duration>? _posSub;
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
          .register(step: _step, jump: _jump);
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
      _open();
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
  void dispose() {
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
          SizedBox(
            height: 80,
            width: 480,
            child: Video(controller: _controller),
          ),
        ],
      );
    }
    return Video(controller: _controller);
  }
}
