import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../l10n/l10n.dart';
import '../features/feed/feed_screen.dart';
import 'minigame_config.dart';
import 'minigame_scaffold.dart';

/// Social Feed Scrub. config: {"target": postId}
/// Pick the post you think was altered, then compare it with the archive cache.
class FeedScrubGame extends ConsumerStatefulWidget {
  const FeedScrubGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<FeedScrubGame> createState() => _FeedScrubGameState();
}

class _FeedScrubGameState extends ConsumerState<FeedScrubGame> {
  String? _selected;
  final _compared = <String>{};
  double _minutes = 60;

  String? get postTarget {
    final t = widget.interaction.node.config['target'];
    return t is String && !t.contains(':') ? t : null;
  }

  String? get timeTarget => MinigameConfig.scrubTime(widget.interaction.node.config);

  void _compare() {
    final clock = timeTarget;
    if (clock != null) {
      final parts = clock.split(':');
      final want = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if ((_minutes - want).abs() <= 2) {
        ref.minigameSuccess(context, message: 'Frame holds at $clock.');
      } else {
        ref.minigameFail(context, widget.interaction.puzzleId, 'Wrong timestamp.');
      }
      return;
    }
    final id = _selected;
    if (id == null) return;
    if (id == postTarget) {
      ref.read(storyEngineProvider.notifier).applyEffects({
        'flags': ['cache_revealed_$id'],
      });
      setState(() => _compared.add(id));
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) {
          ref.minigameSuccess(
            context,
            message: 'The saved copy still has what she cut.',
          );
        }
      });
    } else {
      setState(() => _compared.add(id));
      ref.minigameFail(
        context,
        widget.interaction.puzzleId,
        'The saved copy matches. Nothing changed here.',
      );
    }
  }

  String _clock(double minutes) {
    final m = minutes.round().clamp(0, 24 * 60 - 1);
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final min = (m % 60).toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final clock = timeTarget;
    if (clock != null) {
      return MinigameScaffold(
        interaction: widget.interaction,
        brief: widget.interaction.node.config['brief'] as String? ??
            'Scrub the tape to the time that matters.',
        bottom: CheckBar(
          onCheck: _compare,
          label: 'Hold this frame',
          status: _clock(_minutes),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
          child: Column(
            children: [
              Text(_clock(_minutes), style: displayStyle.copyWith(fontSize: 42, color: HmColors.teal)),
              const SizedBox(height: 20),
              Slider(
                value: _minutes.clamp(0, 24 * 60 - 1),
                min: 0,
                max: 24 * 60 - 1,
                activeColor: HmColors.teal,
                onChanged: (v) => setState(() => _minutes = v),
              ),
            ],
          ),
        ),
      );
    }
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: widget.interaction.node.config['brief'] as String? ?? 'One of these posts is not what it was. Select it and compare with the saved copy.',
      bottom: CheckBar(
        onCheck: _compare,
        enabled: _selected != null && !_compared.contains(_selected),
        label: 'Compare with cache',
        status: _selected == null
            ? 'select a post'
            : context.fmt('selected · {id}', {'id': _selected}),
      ),
      child: Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: game.feed.length,
          itemBuilder: (context, i) {
            final p = game.feed[i];
            final sel = _selected == p.id;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? HmColors.teal : Colors.transparent,
                  width: 2,
                ),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: FeedCard(
                post: p,
                showCached: game.has('cache_revealed_${p.id}'),
                onTap: () => setState(() => _selected = p.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
