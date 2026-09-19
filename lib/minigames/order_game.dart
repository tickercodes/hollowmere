import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import 'minigame_scaffold.dart';

/// Call Log Reconstruction / timeline ordering.
/// config: {"items": [{"id","text","cue"?,"who"?}], "answer": [ids in order]}
/// Items start shuffled deterministically; drag to reorder, then check.
class OrderGame extends ConsumerStatefulWidget {
  const OrderGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<OrderGame> createState() => _OrderGameState();
}

class _OrderGameState extends ConsumerState<OrderGame> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    final items = (widget.interaction.node.config['items'] as List).cast<Map<String, dynamic>>();
    _items = List.of(items);
    // Deterministic shuffle so the puzzle looks the same on every attempt.
    final n = _items.length;
    for (var i = 0; i < n; i++) {
      final j = (i * 7 + 3) % n;
      final t = _items[i];
      _items[i] = _items[j];
      _items[j] = t;
    }
    final answer = (widget.interaction.node.config['answer'] as List).cast<String>();
    if (_items.map((e) => e['id']).join() == answer.join() && n > 1) {
      _items.insert(0, _items.removeLast());
    }
  }

  void _check() {
    final answer = (widget.interaction.node.config['answer'] as List).cast<String>();
    final current = _items.map((e) => e['id'] as String).toList();
    if (current.join('|') == answer.join('|')) {
      ref.minigameSuccess(context, message: 'The sequence holds together.');
      return;
    }
    var correct = 0;
    for (var i = 0; i < answer.length; i++) {
      if (i < current.length && current[i] == answer[i]) correct++;
    }
    ref.minigameFail(context, widget.interaction.puzzleId,
        '$correct of ${answer.length} in the right place. Listen for what comes before what.');
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.interaction.node.config;
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: cfg['brief'] as String? ?? 'Drag the pieces into the order they happened.',
      bottom: CheckBar(onCheck: _check, status: 'first → last'),
      child: Expanded(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _items.length,
          onReorderItem: (a, b) => setState(() {
            _items.insert(b, _items.removeAt(a));
          }),
          itemBuilder: (context, i) {
            final it = _items[i];
            return Container(
              key: ValueKey(it['id']),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HmColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HmColors.hairline),
              ),
              child: Row(
                children: [
                  Text('${i + 1}', style: monoStyle.copyWith(color: HmColors.teal)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (it['who'] != null)
                          Text((it['who'] as String).toUpperCase(),
                              style: monoStyle.copyWith(fontSize: 10, color: HmColors.amber, letterSpacing: 1.5)),
                        Text(it['text'] as String, style: const TextStyle(height: 1.4)),
                        if (it['cue'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('background: ${it['cue']}',
                                style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.drag_handle_rounded, color: HmColors.textDim),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
