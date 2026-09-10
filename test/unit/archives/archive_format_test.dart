import 'dart:io';

import 'package:cull/data/archives/archive_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('archiveFormatOf', () {
    test('classifies by extension', () {
      expect(archiveFormatOf('a.zip'), ArchiveFormat.zip);
      expect(archiveFormatOf('a.cbz'), ArchiveFormat.zip);
      expect(archiveFormatOf('a.tar'), ArchiveFormat.tar);
      expect(archiveFormatOf('a.cbt'), ArchiveFormat.tar);
      expect(archiveFormatOf('a.tgz'), ArchiveFormat.compressedTar);
      expect(archiveFormatOf('a.tar.gz'), ArchiveFormat.compressedTar);
      expect(archiveFormatOf('a.7z'), ArchiveFormat.sevenZip);
      expect(archiveFormatOf('a.cb7'), ArchiveFormat.sevenZip);
      expect(archiveFormatOf('a.rar'), ArchiveFormat.rar);
      expect(archiveFormatOf('a.cbr'), ArchiveFormat.rar);
      expect(archiveFormatOf('a.iso'), ArchiveFormat.otherReadOnly);
      expect(archiveFormatOf('a.txt'), isNull);
    });

    test('rewrite / native-backend flags', () {
      expect(ArchiveFormat.zip.isRewritable, isTrue);
      expect(ArchiveFormat.zip.needsNativeBackend, isFalse);
      expect(ArchiveFormat.sevenZip.isRewritable, isTrue);
      expect(ArchiveFormat.sevenZip.needsNativeBackend, isTrue);
      expect(ArchiveFormat.rar.isRewritable, isFalse);
      expect(ArchiveFormat.otherReadOnly.isRewritable, isFalse);
    });
  });

  group('sniffArchiveFormat', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('cull_sniff_');
    });
    tearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    Future<File> write(String name, List<int> bytes) async {
      final f = File('${dir.path}${Platform.pathSeparator}$name');
      await f.writeAsBytes(bytes);
      return f;
    }

    test('detects a RAR payload behind a .cbz name', () async {
      final f = await write('mislabelled.cbz', [
        0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00, //
      ]);
      expect(await sniffArchiveFormat(f), ArchiveFormat.rar);
    });

    test('detects 7z magic', () async {
      final f = await write('x.bin', [
        0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C, 0x00, 0x04, //
      ]);
      expect(await sniffArchiveFormat(f), ArchiveFormat.sevenZip);
    });

    test('detects zip magic', () async {
      final f = await write('x.bin', [0x50, 0x4B, 0x03, 0x04, 0, 0, 0, 0]);
      expect(await sniffArchiveFormat(f), ArchiveFormat.zip);
    });

    test('returns null for non-archive bytes', () async {
      final f = await write('x.bin', [0x00, 0x01, 0x02, 0x03, 4, 5, 6, 7]);
      expect(await sniffArchiveFormat(f), isNull);
    });
  });
}
