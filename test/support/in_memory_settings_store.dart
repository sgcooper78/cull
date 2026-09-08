import 'package:cull/data/settings/scrub_settings.dart';
import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/data/settings/sort_settings.dart';

/// [SettingsStore] with no disk IO, for tests.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({this.scrub, this.sort});

  ScrubSettings? scrub;
  SortSettings? sort;

  @override
  Future<ScrubSettings?> loadScrub() async => scrub;

  @override
  Future<void> saveScrub(ScrubSettings settings) async => scrub = settings;

  @override
  Future<SortSettings?> loadSort() async => sort;

  @override
  Future<void> saveSort(SortSettings settings) async => sort = settings;
}
