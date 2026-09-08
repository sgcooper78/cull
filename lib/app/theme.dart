import 'package:flutter/material.dart';

/// Single source of truth for app theming. Desktop-density Material 3.
ThemeData cullTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3A6EA5),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
  );
}
