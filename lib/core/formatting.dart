/// Small display-formatting helpers. Pure, no Flutter imports.
library;

/// Human-readable byte size, e.g. `1.4 MB`, `948 B`.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
  var size = bytes / 1024;
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final precision = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
  return '${size.toStringAsFixed(precision)} ${units[unit]}';
}

/// `2026-09-07 14:32` in local time.
String formatDateTime(DateTime dt) {
  final l = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} '
      '${two(l.hour)}:${two(l.minute)}';
}
