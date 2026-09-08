/// Tunables for [ScrubMode]: how long each preview window plays and how far
/// it jumps between windows (as a percentage of the file's total duration).
class ScrubSettings {
  const ScrubSettings({required this.playSeconds, required this.skipPercent});

  /// Seconds played before each jump. Clamped to 1–30.
  final int playSeconds;

  /// Jump distance as a percent of total duration. Clamped to 5–50, so a
  /// file gets roughly `100 / skipPercent` preview windows.
  final int skipPercent;

  static const defaults = ScrubSettings(playSeconds: 4, skipPercent: 15);

  static const minPlaySeconds = 1;
  static const maxPlaySeconds = 30;
  static const minSkipPercent = 5;
  static const maxSkipPercent = 50;

  Duration get playWindow => Duration(seconds: playSeconds);
  double get skipFraction => skipPercent / 100;

  /// Approximate number of preview windows across one file.
  int get samplesPerFile => (100 / skipPercent).ceil();

  ScrubSettings clamped() => ScrubSettings(
    playSeconds: playSeconds.clamp(minPlaySeconds, maxPlaySeconds),
    skipPercent: skipPercent.clamp(minSkipPercent, maxSkipPercent),
  );

  ScrubSettings copyWith({int? playSeconds, int? skipPercent}) => ScrubSettings(
    playSeconds: playSeconds ?? this.playSeconds,
    skipPercent: skipPercent ?? this.skipPercent,
  );

  Map<String, dynamic> toJson() => {
    'playSeconds': playSeconds,
    'skipPercent': skipPercent,
  };

  factory ScrubSettings.fromJson(Map<String, dynamic> json) => ScrubSettings(
    playSeconds: (json['playSeconds'] as num?)?.toInt() ?? defaults.playSeconds,
    skipPercent: (json['skipPercent'] as num?)?.toInt() ?? defaults.skipPercent,
  ).clamped();

  @override
  bool operator ==(Object other) =>
      other is ScrubSettings &&
      other.playSeconds == playSeconds &&
      other.skipPercent == skipPercent;

  @override
  int get hashCode => Object.hash(playSeconds, skipPercent);
}
