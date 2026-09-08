import '../../core/natural_sort.dart';
import '../fs/fs_entry.dart';

import 'package:path/path.dart' as p;

/// What the tree sorts each folder's entries by.
enum SortKey {
  name,
  size,
  modified,
  type;

  String get label => switch (this) {
    SortKey.name => 'Name',
    SortKey.size => 'Size',
    SortKey.modified => 'Date modified',
    SortKey.type => 'Type',
  };
}

/// Sort preference for the directory tree.
class SortSettings {
  const SortSettings({
    required this.key,
    required this.ascending,
    required this.foldersFirst,
  });

  final SortKey key;
  final bool ascending;

  /// Directories sort before files regardless of [key]/[ascending].
  final bool foldersFirst;

  static const defaults = SortSettings(
    key: SortKey.name,
    ascending: true,
    foldersFirst: true,
  );

  /// Ordering for `List<FsEntry>.sort`.
  int compare(FsEntry a, FsEntry b) {
    if (foldersFirst && a.isDirectory != b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }
    var c = switch (key) {
      SortKey.name => 0,
      SortKey.size => a.size.compareTo(b.size),
      SortKey.modified => a.modified.compareTo(b.modified),
      SortKey.type =>
        p
            .extension(a.name)
            .toLowerCase()
            .compareTo(p.extension(b.name).toLowerCase()),
    };
    if (c == 0) {
      c = naturalCompare(a.name.toLowerCase(), b.name.toLowerCase());
    }
    return ascending ? c : -c;
  }

  SortSettings copyWith({SortKey? key, bool? ascending, bool? foldersFirst}) =>
      SortSettings(
        key: key ?? this.key,
        ascending: ascending ?? this.ascending,
        foldersFirst: foldersFirst ?? this.foldersFirst,
      );

  Map<String, dynamic> toJson() => {
    'key': key.name,
    'ascending': ascending,
    'foldersFirst': foldersFirst,
  };

  factory SortSettings.fromJson(Map<String, dynamic> json) => SortSettings(
    key: SortKey.values.firstWhere(
      (k) => k.name == json['key'],
      orElse: () => defaults.key,
    ),
    ascending: json['ascending'] as bool? ?? defaults.ascending,
    foldersFirst: json['foldersFirst'] as bool? ?? defaults.foldersFirst,
  );

  @override
  bool operator ==(Object other) =>
      other is SortSettings &&
      other.key == key &&
      other.ascending == ascending &&
      other.foldersFirst == foldersFirst;

  @override
  int get hashCode => Object.hash(key, ascending, foldersFirst);
}
