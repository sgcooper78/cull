/// Compares strings so embedded numbers sort by value, not lexically
/// (`page2` before `page10`). Case-sensitive — lower-case the inputs first
/// if you want case-insensitive ordering.
int naturalCompare(String a, String b) {
  final chunk = RegExp(r'\d+|\D+');
  final ta = chunk.allMatches(a).map((m) => m[0]!).toList();
  final tb = chunk.allMatches(b).map((m) => m[0]!).toList();

  for (var i = 0; i < ta.length && i < tb.length; i++) {
    final x = ta[i];
    final y = tb[i];
    final nx = int.tryParse(x);
    final ny = int.tryParse(y);
    final cmp = (nx != null && ny != null) ? nx.compareTo(ny) : x.compareTo(y);
    if (cmp != 0) return cmp;
  }
  return ta.length.compareTo(tb.length);
}
