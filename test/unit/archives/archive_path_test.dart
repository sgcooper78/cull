import 'package:cull/data/archives/archive_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('archive-member paths', () {
    test('isArchiveMemberPath detects the separator', () {
      expect(isArchiveMemberPath(r'C:\d\a.7z!/x.jpg'), isTrue);
      expect(isArchiveMemberPath(r'C:\d\a.7z'), isFalse);
      expect(isArchiveMemberPath(r'C:\d\photos.7z\real\x.jpg'), isFalse);
    });

    test('splitArchivePath splits on the first separator', () {
      final (archive, entry) = splitArchivePath(r'C:\d\a.7z!/sub/x.jpg');
      expect(archive, r'C:\d\a.7z');
      expect(entry, 'sub/x.jpg');
    });

    test('nested archives split outermost-first', () {
      final (archive, entry) = splitArchivePath(r'C:\d\a.7z!/inner.zip!/x.jpg');
      expect(archive, r'C:\d\a.7z');
      expect(entry, 'inner.zip!/x.jpg');
      expect(isArchiveMemberPath(entry), isTrue);
    });

    test('rootArchiveOf peels every level', () {
      expect(rootArchiveOf(r'C:\d\a.7z!/inner.zip!/x.jpg'), r'C:\d\a.7z');
      expect(rootArchiveOf(r'C:\d\plain.txt'), r'C:\d\plain.txt');
    });

    test('joinArchivePath normalises the entry part', () {
      expect(
        joinArchivePath(r'C:\d\a.zip', r'\sub\x.jpg\'),
        r'C:\d\a.zip!/sub/x.jpg',
      );
    });
  });

  group('isSafeEntryPath (zip-slip guard)', () {
    test('accepts plain relative paths', () {
      expect(isSafeEntryPath('a/b/c.jpg'), isTrue);
      expect(isSafeEntryPath('file.txt'), isTrue);
    });

    test('rejects traversal, absolute and drive-qualified paths', () {
      expect(isSafeEntryPath('../evil'), isFalse);
      expect(isSafeEntryPath('a/../../evil'), isFalse);
      expect(isSafeEntryPath('/etc/passwd'), isFalse);
      expect(isSafeEntryPath(r'C:\Windows\system32'), isFalse);
      expect(isSafeEntryPath(''), isFalse);
    });
  });

  group('ArchiveEntry', () {
    test('name and parent derive from the internal path', () {
      const e = ArchiveEntry(path: 'a/b/c.jpg', isDir: false, size: 10);
      expect(e.name, 'c.jpg');
      expect(e.parent, 'a/b');

      const top = ArchiveEntry(path: 'readme.txt', isDir: false, size: 1);
      expect(top.name, 'readme.txt');
      expect(top.parent, '');
    });
  });
}
