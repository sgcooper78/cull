import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';

import '../../../core/file_kind.dart';

/// Zoom/pan image viewer. Three paths by [ImageSupport]:
/// native (Flutter decoder), package (`image` CPU decode), or an
/// informational card for formats with no pure-Dart decoder.
class ImageView extends StatelessWidget {
  const ImageView({required this.path, super.key});

  final String path;

  /// `image`-package decode is CPU-bound; don't attempt it past this size.
  static const _decoderMaxBytes = 48 << 20; // 48 MiB

  @override
  Widget build(BuildContext context) {
    return switch (imageSupportOf(path)) {
      ImageSupport.native => _photoView(context, FileImage(File(path))),
      ImageSupport.package => _DecodedImageView(path: path),
      ImageSupport.unsupported => _UnsupportedImage(path: path),
    };
  }

  static Widget _photoView(BuildContext context, ImageProvider provider) {
    return PhotoView(
      imageProvider: provider,
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      errorBuilder: (_, _, _) =>
          const Center(child: Text('Could not decode image')),
    );
  }

  static const decoderMaxBytes = _decoderMaxBytes;
}

/// Top-level so it can run in an isolate via [compute].
Uint8List? decodeImageToPng(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return img.encodePng(decoded);
}

class _DecodedImageView extends StatelessWidget {
  const _DecodedImageView({required this.path});

  final String path;

  Future<Uint8List> _decode() async {
    final file = File(path);
    if (await file.length() > ImageView.decoderMaxBytes) {
      throw const _ImageError('Image is larger than 48 MiB — not decoded.');
    }
    final png = await compute(decodeImageToPng, await file.readAsBytes());
    if (png == null) {
      throw const _ImageError('This image could not be decoded.');
    }
    return png;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _decode(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final e = snap.error;
          return _centered(e is _ImageError ? e.message : 'Decode failed:\n$e');
        }
        return ImageView._photoView(context, MemoryImage(snap.data!));
      },
    );
  }
}

class _UnsupportedImage extends StatelessWidget {
  const _UnsupportedImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ext = path.contains('.') ? path.split('.').last.toUpperCase() : '?';
    return _centered(
      '$ext images have no pure-Dart decoder on desktop.\n'
      'File details are shown above; the pixels can\'t be previewed here.',
    );
  }
}

Widget _centered(String message) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Text(message, textAlign: TextAlign.center),
  ),
);

class _ImageError implements Exception {
  const _ImageError(this.message);
  final String message;
}
