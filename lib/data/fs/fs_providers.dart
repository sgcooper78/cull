import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'file_source.dart';
import 'io_file_source.dart';

part 'fs_providers.g.dart';

/// The active [FileSource]. Desktop uses [IoFileSource]; tests override this.
@Riverpod(keepAlive: true)
FileSource fileSource(Ref ref) => const IoFileSource();
