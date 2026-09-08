import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:watcher/watcher.dart';

import '../../data/fs/fs_entry.dart';
import '../../data/fs/fs_providers.dart';

part 'browse_controller.g.dart';

/// The root directory the tree is showing. Null until the user opens one.
@Riverpod(keepAlive: true)
class Browse extends _$Browse {
  @override
  String? build() => null;

  void openRoot(String path) => state = p.normalize(path);
  void close() => state = null;
}

/// Live contents of [dirPath]: an initial listing plus a refresh whenever the
/// OS reports a change in that folder. One instance per expanded tree node.
@riverpod
Stream<List<FsEntry>> directoryListing(Ref ref, String dirPath) {
  final fs = ref.watch(fileSourceProvider);
  final controller = StreamController<List<FsEntry>>();

  Future<void> refresh() async {
    try {
      controller.add(await fs.list(dirPath));
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(refresh());

  StreamSubscription<WatchEvent>? sub;
  try {
    sub = DirectoryWatcher(dirPath).events
        .listen((_) => refresh(), onError: (_) {});
  } catch (_) {
    // Watching is best-effort; the initial listing still works.
  }

  ref.onDispose(() {
    sub?.cancel();
    controller.close();
  });

  return controller.stream;
}
