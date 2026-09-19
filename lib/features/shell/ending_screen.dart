import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/endings.dart';
import '../../content/evidence.dart';
import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';

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
                Text(ending.subtitle.toUpperCase(),
                    style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 3)),
                const SizedBox(height: 10),
                Text(ending.title, style: displayStyle.copyWith(fontSize: 34)),
                const SizedBox(height: 28),
                for (final p in endingCopy(ending, fullTrust: _fullTrust(game)))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(p, style: const TextStyle(fontSize: 16, height: 1.6)),
                  ),
                const Divider(height: 40),
                Text('WHY THIS ENDING',
                    style: monoStyle.copyWith(color: HmColors.textDim, letterSpacing: 2, fontSize: 11)),
                const SizedBox(height: 10),
                _Fact('Evidence on file', '${game.evidenceCount} of ${evidenceCatalog.length}'),
                _Fact('Accused', game.flags.where((f) => f.startsWith('accused_')).map((f) => f.substring(8)).join(', ').toUpperCase()),
                _Fact('Episode 5 fork', game.has('fork_alone') ? 'went alone' : game.has('fork_police') ? 'went to the police' : '-'),
                _Fact('Bait', game.has('bait_north_dock') ? 'north dock' : 'none'),
                _Fact('Trust', 'Jonah ${game.trustOf('jonah')} · Deacon ${game.trustOf('deacon')} · Mara ${game.trustOf('mara')} · Tess ${game.trustOf('tess')}'),
                _Fact('Endings found', '$unlocked of ${endings.length}'),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    engine.applyEffects({'flags': ['seen_ending_$endingId']});
                    engine.backToMenu();
                  },
                  child: const Text('Return to menu'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    engine.applyEffects({'flags': ['seen_ending_$endingId']});
                    engine.startEpisode('ep5');
                  },
                  child: const Text('Replay from Episode 5'),
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
            SizedBox(width: 140, child: Text(k, style: const TextStyle(color: HmColors.textDim))),
            Expanded(child: Text(v.isEmpty ? '-' : v, style: monoStyle)),
          ],
        ),
      );
}
