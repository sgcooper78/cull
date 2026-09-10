import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'archive_reader.dart';
import 'composite_archive.dart';

part 'archive_providers.g.dart';

/// The active [ArchiveReader]. Tests override with an in-memory fake.
@Riverpod(keepAlive: true)
ArchiveReader archiveReader(Ref ref) => CompositeArchiveReader();

/// The active [ArchiveWriter] for repackage-on-delete.
@Riverpod(keepAlive: true)
ArchiveWriter archiveWriter(Ref ref) => CompositeArchiveWriter();
