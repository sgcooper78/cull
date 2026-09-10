/// Why an archive operation could not complete. The UI maps these to a message;
/// `data/` never throws across the layer boundary (see CLAUDE.md).
enum ArchiveErrorKind {
  /// The `.zip`/`.7z`/… file itself is not on disk.
  notFound,

  /// The format is recognised but this build has no code path for it — e.g.
  /// `.7z`/`.rar` when the native libarchive backend is not installed.
  nativeBackendMissing,

  /// Not an archive we can open at all (`.dmg`, `.iso` on some platforms…).
  unsupportedFormat,

  /// Larger than the configured in-memory ceiling.
  tooLarge,

  /// Password-protected — browsing and repackaging are both refused in v1.
  encrypted,

  /// Truncated or malformed container.
  corrupt,

  /// A named entry is not present in the archive.
  entryNotFound,

  /// The format can be read but not written, so a repackage-on-delete is
  /// impossible (`.rar`, `.cab`, `.lha`, …).
  notWritable,

  /// Underlying IO failure (disk full while writing the temp copy, etc.).
  io,
}

/// Result of an archive read/write. Pattern-match on the subtype.
sealed class ArchiveResult<T> {
  const ArchiveResult();

  R when<R>({
    required R Function(T value) ok,
    required R Function(ArchiveErrorKind kind, String message) failure,
  }) {
    final self = this;
    return switch (self) {
      ArchiveOk<T>() => ok(self.value),
      ArchiveFailure<T>() => failure(self.kind, self.message),
    };
  }

  /// The value, or `null` on failure.
  T? get valueOrNull => switch (this) {
    ArchiveOk<T>(:final value) => value,
    ArchiveFailure<T>() => null,
  };
}

class ArchiveOk<T> extends ArchiveResult<T> {
  const ArchiveOk(this.value);
  final T value;
}

class ArchiveFailure<T> extends ArchiveResult<T> {
  const ArchiveFailure(this.kind, [this._message]);

  final ArchiveErrorKind kind;
  final String? _message;

  /// A human-readable reason — the caller-supplied text if any, else a
  /// sensible default for [kind].
  String get message => _message ?? _defaultMessage(kind);

  /// Re-type a failure for a different value type without rebuilding it.
  ArchiveFailure<U> cast<U>() => ArchiveFailure<U>(kind, _message);

  static String _defaultMessage(ArchiveErrorKind kind) => switch (kind) {
    ArchiveErrorKind.notFound => 'Archive not found.',
    ArchiveErrorKind.nativeBackendMissing =>
      '7z / RAR support needs the native archive backend, which is not '
          'installed in this build.',
    ArchiveErrorKind.unsupportedFormat => 'Unsupported archive format.',
    ArchiveErrorKind.tooLarge => 'Archive is too large to open here.',
    ArchiveErrorKind.encrypted => 'Archive is password-protected.',
    ArchiveErrorKind.corrupt => 'Archive is damaged or truncated.',
    ArchiveErrorKind.entryNotFound => 'Entry not found in archive.',
    ArchiveErrorKind.notWritable =>
      'This archive format cannot be rebuilt, so entries inside it cannot be '
          'marked for deletion.',
    ArchiveErrorKind.io => 'Could not read or write the archive.',
  };
}
