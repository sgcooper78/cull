// The binding fields deliberately mirror libarchive's C symbol names
// (`archive_read_new`, `archive_entry_pathname`, …) so this file reads
// alongside the libarchive docs.
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Hand-written FFI surface for libarchive — just the ~30 entry points Cull
/// uses for read-listing and rewrite. libarchive's C ABI is stable, so this is
/// maintained by hand rather than generated (no `ffigen`/libclang needed at
/// build time).
///
/// [tryLoad] returns `null` when the shared library cannot be found, which is
/// the signal the whole native backend is unavailable in this build.
class LibArchive {
  LibArchive._(this._lib) {
    read_new = _lib
        .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
          'archive_read_new',
        );
    read_support_filter_all = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_read_support_filter_all');
    read_support_format_all = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_read_support_format_all');
    read_open_filename = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>, IntPtr),
          int Function(Pointer<Void>, Pointer<Utf8>, int)
        >('archive_read_open_filename');
    read_next_header2 = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Void>),
          int Function(Pointer<Void>, Pointer<Void>)
        >('archive_read_next_header2');
    read_data = _lib
        .lookupFunction<
          IntPtr Function(Pointer<Void>, Pointer<Void>, IntPtr),
          int Function(Pointer<Void>, Pointer<Void>, int)
        >('archive_read_data');
    read_data_skip = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_read_data_skip');
    read_close = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_read_close');
    read_free = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_read_free');

    write_new = _lib
        .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
          'archive_write_new',
        );
    write_set_format_zip = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_set_format_zip');
    write_set_format_7zip = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_set_format_7zip');
    write_set_format_pax_restricted = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_set_format_pax_restricted');
    write_add_filter_none = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_add_filter_none');
    write_add_filter_gzip = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_add_filter_gzip');
    write_open_filename = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Utf8>),
          int Function(Pointer<Void>, Pointer<Utf8>)
        >('archive_write_open_filename');
    write_header = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>, Pointer<Void>),
          int Function(Pointer<Void>, Pointer<Void>)
        >('archive_write_header');
    write_data = _lib
        .lookupFunction<
          IntPtr Function(Pointer<Void>, Pointer<Void>, IntPtr),
          int Function(Pointer<Void>, Pointer<Void>, int)
        >('archive_write_data');
    write_finish_entry = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_finish_entry');
    write_close = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_close');
    write_free = _lib
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_write_free');

    entry_new = _lib
        .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
          'archive_entry_new',
        );
    entry_free = _lib
        .lookupFunction<
          Void Function(Pointer<Void>),
          void Function(Pointer<Void>)
        >('archive_entry_free');
    entry_clear = _lib
        .lookupFunction<
          Pointer<Void> Function(Pointer<Void>),
          Pointer<Void> Function(Pointer<Void>)
        >('archive_entry_clear');
    entry_pathname = _lib
        .lookupFunction<
          Pointer<Utf8> Function(Pointer<Void>),
          Pointer<Utf8> Function(Pointer<Void>)
        >('archive_entry_pathname');
    entry_size = _lib
        .lookupFunction<
          Int64 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_entry_size');
    entry_filetype = _lib
        .lookupFunction<
          Uint32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_entry_filetype');
    entry_mtime = _lib
        .lookupFunction<
          Int64 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('archive_entry_mtime');
    entry_set_pathname = _lib
        .lookupFunction<
          Void Function(Pointer<Void>, Pointer<Utf8>),
          void Function(Pointer<Void>, Pointer<Utf8>)
        >('archive_entry_set_pathname');
    entry_set_size = _lib
        .lookupFunction<
          Void Function(Pointer<Void>, Int64),
          void Function(Pointer<Void>, int)
        >('archive_entry_set_size');
    entry_set_filetype = _lib
        .lookupFunction<
          Void Function(Pointer<Void>, Uint32),
          void Function(Pointer<Void>, int)
        >('archive_entry_set_filetype');
    entry_set_perm = _lib
        .lookupFunction<
          Void Function(Pointer<Void>, Int32),
          void Function(Pointer<Void>, int)
        >('archive_entry_set_perm');
    entry_set_mtime = _lib
        .lookupFunction<
          Void Function(Pointer<Void>, Int64, Int64),
          void Function(Pointer<Void>, int, int)
        >('archive_entry_set_mtime');
    _errorString = _lib
        .lookupFunction<
          Pointer<Utf8> Function(Pointer<Void>),
          Pointer<Utf8> Function(Pointer<Void>)
        >('archive_error_string');
  }

  final DynamicLibrary _lib;

  /// libarchive return codes.
  static const ok = 0;
  static const eof = 1;
  static const warn = -20;
  static const failed = -25;
  static const fatal = -30;

  /// `archive_entry_filetype` masks (from `<sys/stat.h>` conventions).
  static const ifmt = 0xF000;
  static const ifreg = 0x8000;
  static const ifdir = 0x4000;

  late final int Function(Pointer<Void>) read_support_filter_all;
  late final int Function(Pointer<Void>) read_support_format_all;
  late final Pointer<Void> Function() read_new;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) read_open_filename;
  late final int Function(Pointer<Void>, Pointer<Void>) read_next_header2;
  late final int Function(Pointer<Void>, Pointer<Void>, int) read_data;
  late final int Function(Pointer<Void>) read_data_skip;
  late final int Function(Pointer<Void>) read_close;
  late final int Function(Pointer<Void>) read_free;

  late final Pointer<Void> Function() write_new;
  late final int Function(Pointer<Void>) write_set_format_zip;
  late final int Function(Pointer<Void>) write_set_format_7zip;
  late final int Function(Pointer<Void>) write_set_format_pax_restricted;
  late final int Function(Pointer<Void>) write_add_filter_none;
  late final int Function(Pointer<Void>) write_add_filter_gzip;
  late final int Function(Pointer<Void>, Pointer<Utf8>) write_open_filename;
  late final int Function(Pointer<Void>, Pointer<Void>) write_header;
  late final int Function(Pointer<Void>, Pointer<Void>, int) write_data;
  late final int Function(Pointer<Void>) write_finish_entry;
  late final int Function(Pointer<Void>) write_close;
  late final int Function(Pointer<Void>) write_free;

  late final Pointer<Void> Function() entry_new;
  late final void Function(Pointer<Void>) entry_free;
  late final Pointer<Void> Function(Pointer<Void>) entry_clear;
  late final Pointer<Utf8> Function(Pointer<Void>) entry_pathname;
  late final int Function(Pointer<Void>) entry_size;
  late final int Function(Pointer<Void>) entry_filetype;
  late final int Function(Pointer<Void>) entry_mtime;
  late final void Function(Pointer<Void>, Pointer<Utf8>) entry_set_pathname;
  late final void Function(Pointer<Void>, int) entry_set_size;
  late final void Function(Pointer<Void>, int) entry_set_filetype;
  late final void Function(Pointer<Void>, int) entry_set_perm;
  late final void Function(Pointer<Void>, int, int) entry_set_mtime;
  late final Pointer<Utf8> Function(Pointer<Void>) _errorString;

  String errorString(Pointer<Void> archive) {
    final p = _errorString(archive);
    return p == nullptr ? '' : p.toDartString();
  }

  static const _candidates = {
    'windows': ['archive.dll', 'libarchive.dll', 'libarchive-13.dll'],
    'macos': ['libarchive.13.dylib', 'libarchive.dylib'],
    'linux': ['libarchive.so.13', 'libarchive.so'],
  };

  static LibArchive? _cached;
  static bool _tried = false;

  /// Opens the platform libarchive, or returns `null` if it is not present
  /// (the native backend then reports `nativeBackendMissing`). Cached.
  static LibArchive? tryLoad() {
    if (_tried) return _cached;
    _tried = true;
    final names = _candidates[Platform.operatingSystem] ?? const <String>[];
    for (final name in names) {
      try {
        _cached = LibArchive._(DynamicLibrary.open(name));
        return _cached;
      } catch (_) {
        // try the next candidate name
      }
    }
    return null;
  }
}
