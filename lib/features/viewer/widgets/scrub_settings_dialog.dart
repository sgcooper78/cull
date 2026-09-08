import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings/scrub_settings.dart';
import '../scrub_mode_controller.dart';

/// Open the scrub-mode tuning dialog. Changes apply live to any playing media.
Future<void> showScrubSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ScrubSettingsDialog(),
  );
}

class _ScrubSettingsDialog extends ConsumerWidget {
  const _ScrubSettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scrubSettingsControllerProvider);
    final controller = ref.read(scrubSettingsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Scrub mode'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Play for', style: text.labelLarge),
            Slider(
              value: s.playSeconds.toDouble(),
              min: ScrubSettings.minPlaySeconds.toDouble(),
              max: ScrubSettings.maxPlaySeconds.toDouble(),
              divisions:
                  ScrubSettings.maxPlaySeconds - ScrubSettings.minPlaySeconds,
              label: '${s.playSeconds}s',
              onChanged: (v) => controller.setPlaySeconds(v.round()),
            ),
            const SizedBox(height: 8),
            Text('Then skip', style: text.labelLarge),
            Slider(
              value: s.skipPercent.toDouble(),
              min: ScrubSettings.minSkipPercent.toDouble(),
              max: ScrubSettings.maxSkipPercent.toDouble(),
              divisions:
                  (ScrubSettings.maxSkipPercent -
                      ScrubSettings.minSkipPercent) ~/
                  5,
              label: '${s.skipPercent}%',
              onChanged: (v) => controller.setSkipPercent(v.round()),
            ),
            const SizedBox(height: 12),
            Text(
              'Plays ${s.playSeconds}s, jumps ${s.skipPercent}% of the '
              'duration each time — about ${s.samplesPerFile} previews per '
              'file.',
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: controller.reset, child: const Text('Reset')),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
