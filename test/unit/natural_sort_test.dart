import 'package:cull/core/natural_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numbers sort by value, not lexically', () {
    final pages = ['p10.jpg', 'p2.jpg', 'p1.jpg', 'p20.jpg', 'p3.jpg']
      ..sort(naturalCompare);
    expect(pages, ['p1.jpg', 'p2.jpg', 'p3.jpg', 'p10.jpg', 'p20.jpg']);
  });

  test('mixed prefixes and zero-padding', () {
    final names = ['ch1_p2', 'ch1_p10', 'ch2_p1', 'ch1_p1']
      ..sort(naturalCompare);
    expect(names, ['ch1_p1', 'ch1_p2', 'ch1_p10', 'ch2_p1']);
  });

  test('pure text falls back to lexical', () {
    expect(naturalCompare('apple', 'banana'), lessThan(0));
    expect(naturalCompare('b', 'a'), greaterThan(0));
    expect(naturalCompare('same', 'same'), 0);
  });
}
