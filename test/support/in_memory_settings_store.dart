import 'package:cull/data/settings/scrub_settings.dart';
import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/data/settings/sort_settings.dart';

/// [SettingsStore] with no disk IO, for tests.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({this.scrub, this.comicScrub, this.sort});

  MediaScrubSettings? scrub;
  ComicScrubSettings? comicScrub;
  SortSettings? sort;
  Map<String, String> resume = {};
  Map<String, String> comicPages = {};
  List<String> recentFolders = [];

  @override
  Future<MediaScrubSettings?> loadScrub() async => scrub;

  @override
  Future<void> saveScrub(MediaScrubSettings settings) async =>
      scrub = settings;

  @override
  Future<ComicScrubSettings?> loadComicScrub() async => comicScrub;

  @override
  Future<void> saveComicScrub(ComicScrubSettings settings) async =>
      comicScrub = settings;

  @override
  Future<SortSettings?> loadSort() async => sort;

  @override
  Future<void> saveSort(SortSettings settings) async => sort = settings;

  @override
  Future<Map<String, String>> loadResume() async => Map.of(resume);

  @override
  Future<void> saveResume(Map<String, String> lastFileByRoot) async =>
      resume = Map.of(lastFileByRoot);

  @override
  Future<Map<String, String>> loadComicPages() async => Map.of(comicPages);

  @override
  Future<void> saveComicPages(Map<String, String> pageByComicPath) async =>
      comicPages = Map.of(pageByComicPath);

  @override
  Future<List<String>> loadRecentFolders() async => List.of(recentFolders);

  @override
  Future<void> saveRecentFolders(List<String> paths) async =>
      recentFolders = List.of(paths);
}
