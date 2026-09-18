import 'package:cull/core/file_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileKind.isScrubbable', () {
    // isMedia == image || video || audio; isScrubbable == isMedia || comic.
    const expected = {
      FileKind.image: true,
      FileKind.video: true,
      FileKind.audio: true,
      FileKind.pdf: false,
      FileKind.comic: true,
      FileKind.archive: false,
      FileKind.text: false,
      FileKind.other: false,
    };

    for (final kind in FileKind.values) {
      test('$kind isScrubbable is ${expected[kind]}', () {
        expect(kind.isScrubbable, expected[kind]);
      });
    }
  });
}
