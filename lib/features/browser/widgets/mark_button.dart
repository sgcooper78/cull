import 'package:flutter/material.dart';

import '../../../data/marks/mark.dart';

/// The red-✗ / green-✓ toggle. Tapping flips the mark. Used in the sidebar
/// rows and in the viewer header.
class MarkButton extends StatelessWidget {
  const MarkButton({
    required this.mark,
    required this.onChanged,
    this.dense = true,
    super.key,
  });

  final Mark mark;
  final ValueChanged<Mark> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDelete = mark == Mark.delete;
    final color = isDelete ? Colors.red.shade600 : Colors.green.shade600;
    final icon = isDelete ? Icons.cancel : Icons.check_circle;
    final tooltip = isDelete
        ? 'Marked for deletion — click to keep safe'
        : 'Safe — click to mark for deletion';

    return IconButton(
      icon: Icon(icon, color: color),
      iconSize: dense ? 20 : 26,
      visualDensity: dense ? VisualDensity.compact : null,
      tooltip: tooltip,
      onPressed: () => onChanged(mark.toggled()),
    );
  }
}
