import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Required once before any media_kit Player is created.
  MediaKit.ensureInitialized();
  // Loads the pdfium backend for the PDF viewer.
  pdfrxFlutterInitialize();

  runApp(const ProviderScope(child: CullApp()));
}
