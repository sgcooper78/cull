import 'package:cull/core/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBytes', () {
    test('bytes below 1 KiB', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(948), '948 B');
    });

    test('scales through units', () {
      expect(formatBytes(1024), '1.00 KB');
      expect(formatBytes(1536), '1.50 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.00 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.00 GB');
    });

    test('drops decimals as the number grows', () {
      expect(formatBytes(150 * 1024), '150 KB');
      expect(formatBytes(12 * 1024), '12.0 KB');
    });
  });

  test('formatDateTime is zero-padded yyyy-MM-dd HH:mm', () {
    expect(formatDateTime(DateTime(2026, 9, 7, 4, 5)), '2026-09-07 04:05');
  });
}
