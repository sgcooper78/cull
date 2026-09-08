import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'mark.dart';

/// Persists `delete` marks, keyed by absolute path. Absent key == [Mark.safe].
abstract interface class MarkStore {
  Future<Map<String, Mark>> load();
  Future<void> save(Map<String, Mark> marks);

  /// The production store: a JSON sidecar in the app-support directory.
  static Future<MarkStore> open() async {
    final dir = await getApplicationSupportDirectory();
    return JsonFileMarkStore(File(p.join(dir.path, 'marks.json')));
  }
}

/// JSON sidecar on disk.
///
/// Shape: `{"version":1,"marks":{"C:\\a\\b.mp4":"delete", ...}}`
class JsonFileMarkStore implements MarkStore {
  JsonFileMarkStore(this._file);

  final File _file;

  @override
  Future<Map<String, Mark>> load() async {
    if (!await _file.exists()) return {};
    try {
      final raw = jsonDecode(await _file.readAsString());
      final marks = (raw as Map<String, dynamic>)['marks'];
      if (marks is! Map) return {};
      return {
        for (final e in marks.entries)
          e.key as String: Mark.fromWire(e.value as String),
      };
    } on FormatException {
      return {}; // corrupt file — start clean rather than crash
    }
  }

  @override
  Future<void> save(Map<String, Mark> marks) async {
    final deleteOnly = {
      for (final e in marks.entries)
        if (e.value == Mark.delete) e.key: e.value.wireName,
    };
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert({'version': 1, 'marks': deleteOnly}),
    );
  }
}
