import 'package:cull/features/viewer/widgets/comic_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextScrubPageIndex', () {
    test('skip within bounds moves forward without wrapping', () {
      expect(nextScrubPageIndex(current: 2, skip: 3, length: 20), 5);
    });

    test('skip past the end wraps around to the start', () {
      expect(nextScrubPageIndex(current: 8, skip: 5, length: 10), 3);
    });

    test('skip exactly to length wraps to 0', () {
      expect(nextScrubPageIndex(current: 0, skip: 10, length: 10), 0);
    });

    test('length <= 0 is guarded and returns 0', () {
      expect(nextScrubPageIndex(current: 5, skip: 3, length: 0), 0);
      expect(nextScrubPageIndex(current: 5, skip: 3, length: -1), 0);
    });
  });
}
