import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'scrub_settings.dart';
import 'sort_settings.dart';

part 'settings_store.g.dart';

/// The active [SettingsStore]. Tests override this with an in-memory one.
@Riverpod(keepAlive: true)
Future<SettingsStore> settingsStore(Ref ref) => SettingsStore.open();

/// Persists user settings. Same pattern as `MarkStore`: an interface with a
/// JSON-file implementation for production and an in-memory one for tests.
abstract interface class SettingsStore {
  Future<ScrubSettings?> loadScrub();
  Future<void> saveScrub(ScrubSettings settings);

  Future<SortSettings?> loadSort();
  Future<void> saveSort(SortSettings settings);

  /// Last file viewed in each root directory (`{root: filePath}`), so
  /// reopening a directory can jump straight back to where triage left off.
  Future<Map<String, String>> loadResume();
  Future<void> saveResume(Map<String, String> lastFileByRoot);

  /// Recently opened root folders, most-recent first.
  Future<List<String>> loadRecentFolders();
  Future<void> saveRecentFolders(List<String> paths);

  static Future<SettingsStore> open() async {
    final dir = await getApplicationSupportDirectory();
    return JsonFileSettingsStore(File(p.join(dir.path, 'settings.json')));
  }
}

/// `settings.json` in the app-support directory:
/// `{"scrub":{...},"sort":{"key":"name","ascending":true,"foldersFirst":true}}`
class JsonFileSettingsStore implements SettingsStore {
  JsonFileSettingsStore(this._file);

  final File _file;

  Future<Map<String, dynamic>> _readAll() async {
    if (!await _file.exists()) return {};
    try {
      final raw = jsonDecode(await _file.readAsString());
      return raw is Map<String, dynamic> ? raw : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> _writeKey(String key, Object? value) async {
    final all = await _readAll()
      ..[key] = value;
    await _file.parent.create(recursive: true);
    await _file.writeAsString(const JsonEncoder.withIndent('  ').convert(all));
  }

  @override
  Future<ScrubSettings?> loadScrub() async {
    final scrub = (await _readAll())['scrub'];
    if (scrub is! Map<String, dynamic>) return null;
    return ScrubSettings.fromJson(scrub);
  }

  @override
  Future<void> saveScrub(ScrubSettings settings) =>
      _writeKey('scrub', settings.toJson());

  @override
  Future<SortSettings?> loadSort() async {
    final sort = (await _readAll())['sort'];
    if (sort is! Map<String, dynamic>) return null;
    return SortSettings.fromJson(sort);
  }

  @override
  Future<void> saveSort(SortSettings settings) =>
      _writeKey('sort', settings.toJson());

  @override
  Future<Map<String, String>> loadResume() async {
    final resume = (await _readAll())['resume'];
    if (resume is! Map) return {};
    return {
      for (final e in resume.entries)
        if (e.value is String) '${e.key}': e.value as String,
    };
  }

  @override
  Future<void> saveResume(Map<String, String> lastFileByRoot) =>
      _writeKey('resume', lastFileByRoot);

  @override
  Future<List<String>> loadRecentFolders() async {
    final recent = (await _readAll())['recent'];
    if (recent is! List) return [];
    return [
      for (final e in recent)
        if (e is String) e,
    ];
  }

  @override
  Future<void> saveRecentFolders(List<String> paths) =>
      _writeKey('recent', paths);
}
