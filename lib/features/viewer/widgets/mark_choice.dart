import 'package:flutter/material.dart';

import '../../../data/marks/mark.dart';

/// Explicit Delete / Keep pair for the viewer header. Shows the current mark
/// and lets the user set either state directly (Keep = "undelete").
class MarkChoice extends StatelessWidget {
  const MarkChoice({required this.mark, required this.onChanged, super.key});

  final Mark mark;
  final ValueChanged<Mark> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Mark>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: Mark.delete,
          icon: Icon(Icons.cancel, color: Colors.red.shade600),
          label: const Text('Delete'),
        ),
        ButtonSegment(
          value: Mark.safe,
          icon: Icon(Icons.check_circle, color: Colors.green.shade600),
          label: const Text('Keep'),
        ),
      ],
      selected: {mark},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
