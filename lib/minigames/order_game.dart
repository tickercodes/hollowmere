import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../engine/story_engine.dart';
import 'minigame_config.dart';
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
  final _listKey = GlobalKey();
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    final items = MinigameConfig.orderItems(widget.interaction.node.config);
    _items = List.of(items);
    // Deterministic shuffle so the puzzle looks the same on every attempt.
    final n = _items.length;
    for (var i = 0; i < n; i++) {
      final j = (i * 7 + 3) % n;
      final t = _items[i];
      _items[i] = _items[j];
      _items[j] = t;
    }
    final answer = MinigameConfig.orderAnswer(widget.interaction.node.config);
    if (_items.map((e) => e['id']).join() == answer.join() && n > 1) {
      _items.insert(0, _items.removeLast());
    }
  }

  void _check() {
    final answer = MinigameConfig.orderAnswer(widget.interaction.node.config);
    final current = _items.map((e) => e['id'] as String).toList();
    if (current.join('|') == answer.join('|')) {
      ref.minigameSuccess(context, message: 'The sequence holds together.');
      return;
    }
    var correct = 0;
    for (var i = 0; i < answer.length; i++) {
      if (i < current.length && current[i] == answer[i]) correct++;
    }
    ref.minigameFail(
      context,
      widget.interaction.puzzleId,
      L10nCatalog.format(
        '{correct} of {total} in the right place. Listen for what comes before what.',
        {'correct': correct, 'total': answer.length},
      ),
    );
  }

  void _move(String id, int target) {
    final from = _items.indexWhere((e) => e['id'] == id);
    if (from < 0 || from == target) return;
    setState(() {
      final item = _items.removeAt(from);
      _items.insert(from < target ? target - 1 : target, item);
    });
  }

  void _fit(double maxHeight) {
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.height <= 0) return;
    final next = box.size.height > maxHeight ? maxHeight / box.size.height : 1.0;
    if ((next - _scale).abs() > 0.01) setState(() => _scale = next);
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fit(constraints.maxHeight);
            });
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth - 24,
                  child: Column(
                    key: _listKey,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        _OrderTile(
                          index: i,
                          item: _items[i],
                          width: constraints.maxWidth - 24,
                          scale: _scale,
                          onAccept: _move,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.index,
    required this.item,
    required this.width,
    required this.scale,
    required this.onAccept,
  });

  final int index;
  final Map<String, dynamic> item;
  final double width;
  final double scale;
  final void Function(String id, int target) onAccept;

  String get _id => item['id'] as String;

  @override
  Widget build(BuildContext context) {
    final card = _card(context);
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != _id,
      onAcceptWithDetails: (d) => onAccept(d.data, index),
      builder: (context, candidate, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: candidate.isNotEmpty
                  ? Border.all(color: HmColors.teal, width: 1.5)
                  : null,
            ),
            child: Draggable<String>(
              data: _id,
              axis: Axis.vertical,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: width * scale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: width,
                      child: _card(context, dragging: true),
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card),
              child: card,
            ),
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, {bool dragging = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HmColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dragging ? HmColors.teal : HmColors.hairline),
        boxShadow: dragging
            ? const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))]
            : null,
      ),
      child: Row(
        children: [
          Text('${index + 1}', style: monoStyle.copyWith(color: HmColors.teal)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item['who'] != null)
                  Text((item['who'] as String).toUpperCase(),
                      style: monoStyle.copyWith(fontSize: 10, color: HmColors.amber, letterSpacing: 1.5)),
                Text(context.tr(item['text'] as String), style: const TextStyle(height: 1.4)),
                if (item['cue'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(context.fmt('background: {cue}', {'cue': item['cue']}),
                        style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                  ),
              ],
            ),
          ),
          const Icon(Icons.drag_handle_rounded, color: HmColors.textDim),
        ],
      ),
    );
  }
}
