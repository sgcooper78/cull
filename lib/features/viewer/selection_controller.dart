import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/fs/fs_entry.dart';

part 'selection_controller.g.dart';

/// The file open in the viewer pane, or null when nothing is selected.
@Riverpod(keepAlive: true)
class Selection extends _$Selection {
  @override
  FsEntry? build() => null;

  void select(FsEntry entry) => state = entry;
  void clear() => state = null;
}
