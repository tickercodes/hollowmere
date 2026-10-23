import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/endings.dart';
import '../../content/evidence.dart';
import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';

/// The resolved ending: image, title, epilogue paragraphs, and what changed it.
class EndingScreen extends ConsumerWidget {
  const EndingScreen({super.key, required this.endingId});
  final String endingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ending = endings[endingId] ?? endings['radio_silence']!;
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final engine = ref.read(storyEngineProvider.notifier);
    final unlocked = endings.keys.where((k) => game.flags.contains('seen_ending_$k')).length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(photoOf(ending.image).asset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88000000), Color(0xF20A0C0E), HmColors.bg],
                stops: [0, 0.45, 0.7],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
              children: [
                Text(context.tr(ending.subtitle).toUpperCase(),
                    style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 3)),
                const SizedBox(height: 10),
                Text(context.tr(ending.title), style: displayStyle.copyWith(fontSize: 34)),
                const SizedBox(height: 28),
                for (final p in endingCopy(ending, fullTrust: _fullTrust(game)))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(context.tr(p), style: const TextStyle(fontSize: 16, height: 1.6)),
                  ),
                const Divider(height: 40),
                Text(context.tr('WHY THIS ENDING'),
                    style: monoStyle.copyWith(color: HmColors.textDim, letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 10),
                _Fact(context.tr('Evidence on file'), context.fmt('{found} of {total}', {
                  'found': game.evidenceCount,
                  'total': evidenceCatalog.length,
                })),
                _Fact(context.tr('Accused'), game.flags.where((f) => f.startsWith('accused_')).map((f) => f.substring(8)).join(', ').toUpperCase()),
                _Fact(context.tr('Episode 20 fork'), context.tr(game.has('fork_alone') ? 'went alone' : game.has('fork_police') ? 'went to the police' : '-')),
                _Fact(context.tr('Bait'), context.tr(game.has('bait_north_dock') ? 'north dock' : 'none')),
                _Fact(context.tr('Trust'), context.fmt('Jonah {j} · Deacon {d} · Mara {m} · Tess {t}', {
                  'j': game.trustOf('jonah'),
                  'd': game.trustOf('deacon'),
                  'm': game.trustOf('mara'),
                  't': game.trustOf('tess'),
                })),
                _Fact(context.tr('Endings found'), context.fmt('{found} of {total}', {
                  'found': unlocked,
                  'total': endings.length,
                })),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    engine.applyEffects({'flags': ['seen_ending_$endingId']});
                    engine.backToMenu();
                  },
                  child: Text(context.tr('Return to menu')),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    engine.applyEffects({'flags': ['seen_ending_$endingId']});
                    engine.startEpisode('ep20');
                  },
                  child: Text(context.tr('Replay from Episode 20')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _fullTrust(GameState game) =>
    game.trustOf('jonah') >= 1 &&
    game.trustOf('tess') >= 1 &&
    game.trustOf('deacon') >= 1 &&
    game.trustOf('mara') >= 1;

class _Fact extends StatelessWidget {
  const _Fact(this.k, this.v);
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 140, child: Text(context.tr(k), style: const TextStyle(color: HmColors.textDim))),
            Expanded(child: Text(v.isEmpty ? '-' : v, style: monoStyle)),
          ],
        ),
      );
}
