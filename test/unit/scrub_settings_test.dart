import 'package:cull/data/settings/scrub_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaScrubSettings', () {
    test('defaults', () {
      expect(MediaScrubSettings.defaults.playSeconds, 4);
      expect(MediaScrubSettings.defaults.skipPercent, 15);
    });

    test('samplesPerFile ~= 100 / skipPercent, rounded up', () {
      MediaScrubSettings at(int pct) =>
          MediaScrubSettings(playSeconds: 4, skipPercent: pct);
      expect(at(5).samplesPerFile, 20);
      expect(at(10).samplesPerFile, 10);
      expect(at(15).samplesPerFile, 7);
      expect(at(20).samplesPerFile, 5);
      expect(at(25).samplesPerFile, 4);
      expect(at(50).samplesPerFile, 2);
    });

    test('derived values', () {
      const s = MediaScrubSettings(playSeconds: 6, skipPercent: 20);
      expect(s.playWindow, const Duration(seconds: 6));
      expect(s.skipFraction, 0.2);
    });

    test('clamped() pins values into range', () {
      expect(
        const MediaScrubSettings(
          playSeconds: 999,
          skipPercent: 99,
        ).clamped(),
        const MediaScrubSettings(playSeconds: 30, skipPercent: 50),
      );
      expect(
        const MediaScrubSettings(playSeconds: 0, skipPercent: 0).clamped(),
        const MediaScrubSettings(playSeconds: 1, skipPercent: 1),
      );
    });

    test('copyWith', () {
      const s = MediaScrubSettings.defaults;
      expect(s.copyWith(skipPercent: 30).skipPercent, 30);
      expect(s.copyWith(skipPercent: 30).playSeconds, s.playSeconds);
    });

    test('json round-trips, and fromJson clamps / fills gaps', () {
      const s = MediaScrubSettings(playSeconds: 8, skipPercent: 25);
      expect(MediaScrubSettings.fromJson(s.toJson()), s);

      expect(
        MediaScrubSettings.fromJson({'playSeconds': 500}),
        MediaScrubSettings(
          playSeconds: 30,
          skipPercent: MediaScrubSettings.defaults.skipPercent,
        ),
      );
      expect(
        MediaScrubSettings.fromJson(const {}),
        MediaScrubSettings.defaults,
      );
    });

    test('value equality', () {
      expect(
        const MediaScrubSettings(playSeconds: 4, skipPercent: 15),
        const MediaScrubSettings(playSeconds: 4, skipPercent: 15),
      );
      expect(
        const MediaScrubSettings(playSeconds: 4, skipPercent: 15),
        isNot(const MediaScrubSettings(playSeconds: 5, skipPercent: 15)),
      );
      expect(
        const MediaScrubSettings(
          playSeconds: 4,
          skipPercent: 15,
        ).hashCode,
        const MediaScrubSettings(playSeconds: 4, skipPercent: 15).hashCode,
      );
    });
  });

  group('ComicScrubSettings', () {
    test('defaults', () {
      expect(ComicScrubSettings.defaults.pageSeconds, 5);
      expect(ComicScrubSettings.defaults.pageSkip, 5);
    });

    test('dwell derives from pageSeconds', () {
      const s = ComicScrubSettings(pageSeconds: 7, pageSkip: 3);
      expect(s.dwell, const Duration(seconds: 7));
    });

    test('clamped() pins pageSeconds into 1-30', () {
      expect(
        const ComicScrubSettings(pageSeconds: 999, pageSkip: 5).clamped(),
        const ComicScrubSettings(pageSeconds: 30, pageSkip: 5),
      );
      expect(
        const ComicScrubSettings(pageSeconds: 0, pageSkip: 5).clamped(),
        const ComicScrubSettings(pageSeconds: 1, pageSkip: 5),
      );
    });

    test('clamped() pins pageSkip into 1-50', () {
      expect(
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 999).clamped(),
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 50),
      );
      expect(
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 0).clamped(),
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 1),
      );
    });

    test('copyWith', () {
      const s = ComicScrubSettings.defaults;
      expect(s.copyWith(pageSkip: 12).pageSkip, 12);
      expect(s.copyWith(pageSkip: 12).pageSeconds, s.pageSeconds);
    });

    test('json round-trips, and fromJson clamps / fills gaps', () {
      const s = ComicScrubSettings(pageSeconds: 9, pageSkip: 40);
      expect(ComicScrubSettings.fromJson(s.toJson()), s);

      expect(
        ComicScrubSettings.fromJson({'pageSeconds': 500}),
        ComicScrubSettings(
          pageSeconds: 30,
          pageSkip: ComicScrubSettings.defaults.pageSkip,
        ),
      );
      expect(
        ComicScrubSettings.fromJson(const {}),
        ComicScrubSettings.defaults,
      );
    });

    test('value equality', () {
      expect(
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 5),
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 5),
      );
      expect(
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 5),
        isNot(const ComicScrubSettings(pageSeconds: 6, pageSkip: 5)),
      );
      expect(
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 5).hashCode,
        const ComicScrubSettings(pageSeconds: 5, pageSkip: 5).hashCode,
      );
    });
  });
}
