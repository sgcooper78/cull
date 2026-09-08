import 'package:cull/data/fs/fs_entry.dart';
import 'package:cull/data/settings/sort_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/paths.dart';

FsEntry _e(String name, {bool dir = false, int size = 0, DateTime? modified}) =>
    FsEntry(
      path: tp('root/$name'),
      isDirectory: dir,
      size: size,
      modified: modified ?? DateTime(2026),
      accessed: DateTime(2026),
      changed: DateTime(2026),
    );

void main() {
  test('defaults', () {
    expect(SortSettings.defaults.key, SortKey.name);
    expect(SortSettings.defaults.ascending, isTrue);
    expect(SortSettings.defaults.foldersFirst, isTrue);
  });

  List<String> sorted(List<FsEntry> items, SortSettings s) =>
      (items..sort(s.compare)).map((e) => e.name).toList();

  test('by name, ascending and descending', () {
    final items = [_e('b.txt'), _e('a.txt'), _e('c.txt')];
    expect(sorted([...items], SortSettings.defaults), [
      'a.txt',
      'b.txt',
      'c.txt',
    ]);
    expect(
      sorted([...items], SortSettings.defaults.copyWith(ascending: false)),
      ['c.txt', 'b.txt', 'a.txt'],
    );
  });

  test('name uses natural (numeric) order', () {
    final items = [_e('p10.jpg'), _e('p2.jpg'), _e('p1.jpg')];
    expect(sorted(items, SortSettings.defaults), [
      'p1.jpg',
      'p2.jpg',
      'p10.jpg',
    ]);
  });

  test('foldersFirst keeps dirs on top regardless of key or direction', () {
    final items = [_e('zzz'), _e('a.txt', size: 999), _e('m', dir: true)];
    // dir is "m"; note "zzz" is a file here
    final bySize = SortSettings(
      key: SortKey.size,
      ascending: false,
      foldersFirst: true,
    );
    expect(sorted(items, bySize).first, 'm');
  });

  test('foldersFirst off interleaves', () {
    final items = [_e('m', dir: true), _e('a.txt')];
    final s = SortSettings(
      key: SortKey.name,
      ascending: true,
      foldersFirst: false,
    );
    expect(sorted(items, s), ['a.txt', 'm']);
  });

  test('by size', () {
    final items = [
      _e('big', size: 900),
      _e('small', size: 10),
      _e('mid', size: 100),
    ];
    final s = SortSettings(
      key: SortKey.size,
      ascending: true,
      foldersFirst: false,
    );
    expect(sorted(items, s), ['small', 'mid', 'big']);
  });

  test('by date modified', () {
    final items = [
      _e('new', modified: DateTime(2026, 6)),
      _e('old', modified: DateTime(2020)),
      _e('mid', modified: DateTime(2023)),
    ];
    final s = SortSettings(
      key: SortKey.modified,
      ascending: true,
      foldersFirst: false,
    );
    expect(sorted(items, s), ['old', 'mid', 'new']);
  });

  test('by type (extension), name as tiebreak', () {
    final items = [_e('b.txt'), _e('a.txt'), _e('c.jpg')];
    final s = SortSettings(
      key: SortKey.type,
      ascending: true,
      foldersFirst: false,
    );
    expect(sorted(items, s), ['c.jpg', 'a.txt', 'b.txt']);
  });

  test('json round-trips and fills gaps', () {
    const s = SortSettings(
      key: SortKey.size,
      ascending: false,
      foldersFirst: false,
    );
    expect(SortSettings.fromJson(s.toJson()), s);
    expect(SortSettings.fromJson(const {}), SortSettings.defaults);
    expect(
      SortSettings.fromJson({'key': 'bogus'}).key,
      SortSettings.defaults.key,
    );
  });
}
