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

  Future<void> _writeKey(String key, Map<String, dynamic> value) async {
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
}
