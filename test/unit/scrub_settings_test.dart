import 'package:cull/data/settings/scrub_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults', () {
    expect(ScrubSettings.defaults.playSeconds, 4);
    expect(ScrubSettings.defaults.skipPercent, 15);
  });

  test('samplesPerFile ~= 100 / skipPercent, rounded up', () {
    ScrubSettings at(int pct) =>
        ScrubSettings(playSeconds: 4, skipPercent: pct);
    expect(at(5).samplesPerFile, 20);
    expect(at(10).samplesPerFile, 10);
    expect(at(15).samplesPerFile, 7);
    expect(at(20).samplesPerFile, 5);
    expect(at(25).samplesPerFile, 4);
    expect(at(50).samplesPerFile, 2);
  });

  test('derived values', () {
    const s = ScrubSettings(playSeconds: 6, skipPercent: 20);
    expect(s.playWindow, const Duration(seconds: 6));
    expect(s.skipFraction, 0.2);
  });

  test('clamped() pins values into range', () {
    expect(
      const ScrubSettings(playSeconds: 999, skipPercent: 99).clamped(),
      const ScrubSettings(playSeconds: 30, skipPercent: 50),
    );
    expect(
      const ScrubSettings(playSeconds: 0, skipPercent: 1).clamped(),
      const ScrubSettings(playSeconds: 1, skipPercent: 5),
    );
  });

  test('copyWith', () {
    const s = ScrubSettings.defaults;
    expect(s.copyWith(skipPercent: 30).skipPercent, 30);
    expect(s.copyWith(skipPercent: 30).playSeconds, s.playSeconds);
  });

  test('json round-trips, and fromJson clamps / fills gaps', () {
    const s = ScrubSettings(playSeconds: 8, skipPercent: 25);
    expect(ScrubSettings.fromJson(s.toJson()), s);

    expect(
      ScrubSettings.fromJson({'playSeconds': 500}),
      ScrubSettings(
        playSeconds: 30,
        skipPercent: ScrubSettings.defaults.skipPercent,
      ),
    );
    expect(ScrubSettings.fromJson(const {}), ScrubSettings.defaults);
  });

  test('value equality', () {
    expect(
      const ScrubSettings(playSeconds: 4, skipPercent: 15),
      const ScrubSettings(playSeconds: 4, skipPercent: 15),
    );
    expect(
      const ScrubSettings(playSeconds: 4, skipPercent: 15),
      isNot(const ScrubSettings(playSeconds: 5, skipPercent: 15)),
    );
  });
}
