import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings/scrub_settings.dart';
import '../scrub_mode_controller.dart';

/// Open the scrub-mode tuning dialog. Changes apply live to any playing media
/// or open comic.
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
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Scrub mode'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video / Audio', style: text.titleSmall),
            const SizedBox(height: 8),
            const _MediaScrubSection(),
            const SizedBox(height: 20),
            Text('Comic pages (CBZ/CBT)', style: text.titleSmall),
            const SizedBox(height: 8),
            const _ComicScrubSection(),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _MediaScrubSection extends ConsumerWidget {
  const _MediaScrubSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(mediaScrubSettingsControllerProvider);
    final controller = ref.read(mediaScrubSettingsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Play for', style: text.labelLarge),
        Slider(
          value: s.playSeconds.toDouble(),
          min: MediaScrubSettings.minPlaySeconds.toDouble(),
          max: MediaScrubSettings.maxPlaySeconds.toDouble(),
          divisions:
              MediaScrubSettings.maxPlaySeconds -
              MediaScrubSettings.minPlaySeconds,
          label: '${s.playSeconds}s',
          onChanged: (v) => controller.setPlaySeconds(v.round()),
        ),
        const SizedBox(height: 8),
        Text('Then skip', style: text.labelLarge),
        Slider(
          value: s.skipPercent.toDouble(),
          min: MediaScrubSettings.minSkipPercent.toDouble(),
          max: MediaScrubSettings.maxSkipPercent.toDouble(),
          divisions:
              MediaScrubSettings.maxSkipPercent -
              MediaScrubSettings.minSkipPercent,
          label: '${s.skipPercent}%',
          onChanged: (v) => controller.setSkipPercent(v.round()),
        ),
        const SizedBox(height: 12),
        Text(
          'Plays ${s.playSeconds}s, jumps ${s.skipPercent}% of the '
          'duration each time — about ${s.samplesPerFile} previews per '
          'file.',
          style: text.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.reset,
            child: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}

class _ComicScrubSection extends ConsumerWidget {
  const _ComicScrubSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(comicScrubSettingsControllerProvider);
    final controller = ref.read(comicScrubSettingsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Show each page for', style: text.labelLarge),
        Slider(
          value: s.pageSeconds.toDouble(),
          min: ComicScrubSettings.minPageSeconds.toDouble(),
          max: ComicScrubSettings.maxPageSeconds.toDouble(),
          divisions:
              ComicScrubSettings.maxPageSeconds -
              ComicScrubSettings.minPageSeconds,
          label: '${s.pageSeconds}s',
          onChanged: (v) => controller.setPageSeconds(v.round()),
        ),
        const SizedBox(height: 8),
        Text('Then skip', style: text.labelLarge),
        Slider(
          value: s.pageSkip.toDouble(),
          min: ComicScrubSettings.minPageSkip.toDouble(),
          max: ComicScrubSettings.maxPageSkip.toDouble(),
          divisions:
              ComicScrubSettings.maxPageSkip - ComicScrubSettings.minPageSkip,
          label: '${s.pageSkip} pages',
          onChanged: (v) => controller.setPageSkip(v.round()),
        ),
        const SizedBox(height: 12),
        Text(
          'Shows each page for ${s.pageSeconds}s, jumps ${s.pageSkip} '
          'pages each time.',
          style: text.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.reset,
            child: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}
