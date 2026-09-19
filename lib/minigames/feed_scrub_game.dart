import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../features/feed/feed_screen.dart';
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

  String get target => widget.interaction.node.config['target'] as String;

  void _compare() {
    final id = _selected;
    if (id == null) return;
    if (id == target) {
      ref.read(storyEngineProvider.notifier).applyEffects({'flags': ['cache_revealed_$id']});
      setState(() => _compared.add(id));
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) ref.minigameSuccess(context, message: 'The saved copy still has what she cut.');
      });
    } else {
      setState(() => _compared.add(id));
      ref.minigameFail(context, widget.interaction.puzzleId, 'The saved copy matches. Nothing changed here.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: widget.interaction.node.config['brief'] as String? ??
          'One of these posts is not what it was. Select it and compare with the saved copy.',
      bottom: CheckBar(
        onCheck: _compare,
        enabled: _selected != null && !_compared.contains(_selected),
        label: 'Compare with cache',
        status: _selected == null ? 'select a post' : 'selected · ${_selected!}',
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
                border: Border.all(color: sel ? HmColors.teal : Colors.transparent, width: 2),
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
