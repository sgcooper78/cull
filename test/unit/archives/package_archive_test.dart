import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cull/data/archives/archive_result.dart';
import 'package:cull/data/archives/package_archive_reader.dart';
import 'package:cull/data/archives/package_archive_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cull_pkgarch_');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  String path(String name) => '${dir.path}${Platform.pathSeparator}$name';

  Future<String> writeZip(Map<String, String> entries) async {
    final archive = Archive();
    entries.forEach((name, body) {
      archive.add(ArchiveFile.bytes(name, utf8.encode(body)));
    });
    final p = path('sample.zip');
    await File(p).writeAsBytes(ZipEncoder().encodeBytes(archive));
    return p;
  }

  group('PackageArchiveReader', () {
    test('lists files and synthesises missing parent dirs', () async {
      final zip = await writeZip({
        'photos/a.jpg': 'aaa',
        'photos/sub/b.jpg': 'bbb',
        'readme.txt': 'hi',
      });
      const reader = PackageArchiveReader();

      final result = await reader.list(zip);
      final entries = (result as ArchiveOk).value;
      final byPath = {for (final e in entries) e.path: e};

      expect(byPath['photos/a.jpg']!.isDir, isFalse);
      expect(byPath['photos/a.jpg']!.size, 3);
      expect(byPath['readme.txt']!.isDir, isFalse);
      expect(byPath['photos']!.isDir, isTrue);
      expect(byPath['photos/sub']!.isDir, isTrue);
    });

    test('readEntry returns the uncompressed bytes', () async {
      final zip = await writeZip({'dir/hello.txt': 'hello world'});
      const reader = PackageArchiveReader();

      final result = await reader.readEntry(zip, 'dir/hello.txt');
      expect(utf8.decode((result as ArchiveOk).value), 'hello world');
    });

    test('readEntry reports a missing entry', () async {
      final zip = await writeZip({'a.txt': 'a'});
      final result = await const PackageArchiveReader().readEntry(
        zip,
        'nope.txt',
      );
      expect((result as ArchiveFailure).kind, ArchiveErrorKind.entryNotFound);
    });

    test('missing archive file → notFound', () async {
      final result = await const PackageArchiveReader().list(path('ghost.zip'));
      expect((result as ArchiveFailure).kind, ArchiveErrorKind.notFound);
    });

    test('over the byte cap → tooLarge', () async {
      final zip = await writeZip({'a.txt': 'a'});
      final result = await const PackageArchiveReader(maxBytes: 4).list(zip);
      expect((result as ArchiveFailure).kind, ArchiveErrorKind.tooLarge);
    });
  });

  group('PackageArchiveWriter.rewriteWithout', () {
    test('drops the named entry and swaps the file in place', () async {
      final zip = await writeZip({
        'keep.txt': 'keep',
        'drop.txt': 'drop',
        'photos/x.jpg': 'x',
      });
      const writer = PackageArchiveWriter();

      final result = await writer.rewriteWithout(zip, {'drop.txt'});
      expect(result, isA<ArchiveOk<void>>());

      final after = await const PackageArchiveReader().list(zip);
      final paths = [for (final e in (after as ArchiveOk).value) e.path];
      expect(paths, contains('keep.txt'));
      expect(paths, contains('photos/x.jpg'));
      expect(paths, isNot(contains('drop.txt')));
    });

    test('removing a directory drops its whole subtree', () async {
      final zip = await writeZip({
        'photos/a.jpg': 'a',
        'photos/b.jpg': 'b',
        'notes.txt': 'n',
      });

      await const PackageArchiveWriter().rewriteWithout(zip, {'photos'});

      final after = await const PackageArchiveReader().list(zip);
      final files = [
        for (final e in (after as ArchiveOk).value)
          if (!e.isDir) e.path,
      ];
      expect(files, ['notes.txt']);
    });

    test('empty removal set is a no-op success', () async {
      final zip = await writeZip({'a.txt': 'a'});
      final result = await const PackageArchiveWriter().rewriteWithout(zip, {});
      expect(result, isA<ArchiveOk<void>>());
    });

    test('refuses a format it cannot encode', () async {
      final p = path('x.7z');
      await File(p).writeAsBytes([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]);
      final result = await const PackageArchiveWriter().rewriteWithout(p, {
        'a',
      });
      expect((result as ArchiveFailure).kind, ArchiveErrorKind.notWritable);
    });
  });
}
