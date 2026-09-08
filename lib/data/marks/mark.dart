/// Triage state of a file or folder. [safe] is the default and is never
/// persisted — only [delete] marks are written to the sidecar.
enum Mark {
  safe,
  delete;

  Mark toggled() => this == safe ? delete : safe;

  String get wireName => name;

  static Mark fromWire(String s) =>
      Mark.values.firstWhere((m) => m.name == s, orElse: () => Mark.safe);
}
