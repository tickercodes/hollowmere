import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/photos.dart';
import '../../core/glass.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import '../settings/language_picker.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final engine = ref.read(storyEngineProvider.notifier);
    final scripts = ref.read(scriptRepositoryProvider);
    final canResume = game.nodeId != null;
    final hasProgress = canResume || game.completedEpisodes.isNotEmpty;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(photoOf('key_art').asset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Colors.transparent, Color(0xEE0A0C0E)],
                stops: [0, 0.45, 0.85],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(context.tr('A FOUND-PHONE MYSTERY'),
                      textAlign: TextAlign.center,
                      style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 3)),
                  const SizedBox(height: 10),
                  Text(context.tr('THE\nHOLLOWMERE\nFILES'),
                      textAlign: TextAlign.center,
                      style: displayStyle.copyWith(fontSize: 34, height: 1.1)),
                  const Spacer(),
                  if (canResume)
                    FilledButton.icon(
                      onPressed: engine.resume,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(context.fmt('Continue - Episode {n}', {
                        'n': scripts.episode(game.episodeId).number,
                      })),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _startNew(context, ref, hasProgress),
                    icon: const Icon(Icons.fiber_manual_record, size: 14),
                    label: Text(context.tr('New game')),
                  ),
                  if (game.completedEpisodes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _episodeSelect(context, ref),
                      icon: const Icon(Icons.list_rounded),
                      label: Text(context.tr('Episodes')),
                    ),
                  ],
                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: () => showLanguagePicker(context, ref),
                    child: Text(ref.watch(localeProvider).label),
                  ),
                  Text(
                    context.tr('Use headphones for a better experience.'),
                    textAlign: TextAlign.center,
                    style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNew(BuildContext context, WidgetRef ref, bool hasProgress) async {
    final engine = ref.read(storyEngineProvider.notifier);
    if (hasProgress) {
      final ok = await showGlassConfirm(
        context: context,
        kicker: 'New game',
        title: 'Start over?',
        body: 'This erases your current investigation.',
        cancelLabel: 'Keep it',
        confirmLabel: 'Erase',
        destructive: true,
      );
      if (ok != true) return;
      await engine.resetProgress();
    }
    if (!context.mounted) return;
    final name = await showPlayerNameDialog(context);
    if (name == null) return;
    await engine.newGame(playerName: name);
  }

  void _episodeSelect(BuildContext context, WidgetRef ref) {
    final engine = ref.read(storyEngineProvider.notifier);
    final scripts = ref.read(scriptRepositoryProvider);
    final done = ref.read(storyEngineProvider).game.completedEpisodes;
    showGlassSheet(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(c.tr('EPISODES'),
                  style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 2.4, fontSize: 11)),
            ),
            for (final ep in scripts.all)
              ListTile(
                enabled: ep.number == 1 ||
                    done.contains('ep${ep.number - 1}') ||
                    done.contains(ep.id),
                leading: Text('${ep.number}', style: displayStyle.copyWith(fontSize: 20)),
                title: Text(c.tr(ep.title)),
                subtitle: Text(c.tr(done.contains(ep.id) ? 'Completed' : 'Locked'),
                    style: const TextStyle(color: HmColors.textDim)),
                onTap: () {
                  Navigator.pop(c);
                  engine.startEpisode(ep.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}
