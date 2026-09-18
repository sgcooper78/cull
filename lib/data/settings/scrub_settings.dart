/// Tunables for [ScrubMode] applied to video/audio: how long each preview
/// window plays and how far it jumps between windows (as a percentage of the
/// file's total duration).
class MediaScrubSettings {
  const MediaScrubSettings({
    required this.playSeconds,
    required this.skipPercent,
  });

  /// Seconds played before each jump. Clamped to 1–30.
  final int playSeconds;

  /// Jump distance as a percent of total duration. Clamped to 1–50, so a
  /// file gets roughly `100 / skipPercent` preview windows.
  final int skipPercent;

  static const defaults = MediaScrubSettings(playSeconds: 4, skipPercent: 15);

  static const minPlaySeconds = 1;
  static const maxPlaySeconds = 30;
  static const minSkipPercent = 1;
  static const maxSkipPercent = 50;

  Duration get playWindow => Duration(seconds: playSeconds);
  double get skipFraction => skipPercent / 100;

  /// Approximate number of preview windows across one file.
  int get samplesPerFile => (100 / skipPercent).ceil();

  MediaScrubSettings clamped() => MediaScrubSettings(
    playSeconds: playSeconds.clamp(minPlaySeconds, maxPlaySeconds),
    skipPercent: skipPercent.clamp(minSkipPercent, maxSkipPercent),
  );

  MediaScrubSettings copyWith({int? playSeconds, int? skipPercent}) =>
      MediaScrubSettings(
        playSeconds: playSeconds ?? this.playSeconds,
        skipPercent: skipPercent ?? this.skipPercent,
      );

  Map<String, dynamic> toJson() => {
    'playSeconds': playSeconds,
    'skipPercent': skipPercent,
  };

  factory MediaScrubSettings.fromJson(Map<String, dynamic> json) =>
      MediaScrubSettings(
        playSeconds:
            (json['playSeconds'] as num?)?.toInt() ?? defaults.playSeconds,
        skipPercent:
            (json['skipPercent'] as num?)?.toInt() ?? defaults.skipPercent,
      ).clamped();

  @override
  bool operator ==(Object other) =>
      other is MediaScrubSettings &&
      other.playSeconds == playSeconds &&
      other.skipPercent == skipPercent;

  @override
  int get hashCode => Object.hash(playSeconds, skipPercent);
}

/// Tunables for [ScrubMode] applied to comics (`.cbz`/`.cbt`): how long each
/// page is shown before auto-advancing, and how many pages to jump each step.
class ComicScrubSettings {
  const ComicScrubSettings({required this.pageSeconds, required this.pageSkip});

  /// Seconds a page is shown before auto-advancing. Clamped to 1–30.
  final int pageSeconds;

  /// Pages to jump each step. Clamped to 1–50.
  final int pageSkip;

  static const defaults = ComicScrubSettings(pageSeconds: 5, pageSkip: 5);

  static const minPageSeconds = 1;
  static const maxPageSeconds = 30;
  static const minPageSkip = 1;
  static const maxPageSkip = 50;

  Duration get dwell => Duration(seconds: pageSeconds);

  ComicScrubSettings clamped() => ComicScrubSettings(
    pageSeconds: pageSeconds.clamp(minPageSeconds, maxPageSeconds),
    pageSkip: pageSkip.clamp(minPageSkip, maxPageSkip),
  );

  ComicScrubSettings copyWith({int? pageSeconds, int? pageSkip}) =>
      ComicScrubSettings(
        pageSeconds: pageSeconds ?? this.pageSeconds,
        pageSkip: pageSkip ?? this.pageSkip,
      );

  Map<String, dynamic> toJson() => {
    'pageSeconds': pageSeconds,
    'pageSkip': pageSkip,
  };

  factory ComicScrubSettings.fromJson(Map<String, dynamic> json) =>
      ComicScrubSettings(
        pageSeconds:
            (json['pageSeconds'] as num?)?.toInt() ?? defaults.pageSeconds,
        pageSkip: (json['pageSkip'] as num?)?.toInt() ?? defaults.pageSkip,
      ).clamped();

  @override
  bool operator ==(Object other) =>
      other is ComicScrubSettings &&
      other.pageSeconds == pageSeconds &&
      other.pageSkip == pageSkip;

  @override
  int get hashCode => Object.hash(pageSeconds, pageSkip);
}
