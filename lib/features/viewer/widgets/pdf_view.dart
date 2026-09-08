import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Scrollable, zoomable PDF via pdfrx (pdfium). Works on Windows/macOS/Linux.
class PdfView extends StatelessWidget {
  const PdfView({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.file(
      path,
      params: PdfViewerParams(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        errorBannerBuilder: (context, error, stackTrace, documentRef) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not open PDF:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
