import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/mark_store.dart';

/// [MarkStore] with no disk IO — safe inside `testWidgets` (which runs in a
/// FakeAsync zone where real file IO never completes).
class InMemoryMarkStore implements MarkStore {
  Map<String, Mark> _data = {};

  @override
  Future<Map<String, Mark>> load() async => Map.of(_data);

  @override
  Future<void> save(Map<String, Mark> marks) async {
    _data = {
      for (final e in marks.entries)
        if (e.value == Mark.delete) e.key: e.value,
    };
  }
}
