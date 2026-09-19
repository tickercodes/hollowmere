import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../shell/widgets.dart';

/// Wren's mirrored notes (and her search history, stored as `search_*`).
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(storyEngineProvider.notifier).report({'app': 'notes'}));
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(storyEngineProvider.select((s) => s.game.notes));
    final visible = notes.where((n) => !n.id.startsWith('search_')).toList().reversed.toList();
    return AppScaffold(
      title: 'Notes',
      subtitle: "Wren's phone · mirrored",
      body: visible.isEmpty
          ? const EmptyHint('No notes have synced.')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final n = visible[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HmColors.paper,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: const TextStyle(
                              color: HmColors.paperInk, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(n.body,
                          style: const TextStyle(color: HmColors.paperInk, height: 1.5, fontSize: 14.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Sam's own running recap, appended by scripts. Doubles as a "previously on".
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final lines = game.journal.reversed.toList();
    return AppScaffold(
      title: 'Journal',
      subtitle: 'What you know so far',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    _Meter('Jonah', game.trustOf('jonah')),
                    _Meter('Mara', game.trustOf('mara')),
                    _Meter('Deacon', game.trustOf('deacon')),
                    _Meter('Tess', game.trustOf('tess')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _ledgerLine(game),
                  textAlign: TextAlign.center,
                  style: monoStyle.copyWith(fontSize: 10, color: HmColors.textDim, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const EmptyHint('Nothing yet. Start with your last message to her.')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: lines.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0 ? HmColors.teal : HmColors.hairline,
                            ),
                          ),
                          Expanded(child: Text(lines[i], style: const TextStyle(height: 1.5))),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String _ledgerLine(GameState game) {
  final bits = <String>[
    if (game.trustOf('jonah') >= 1) 'Jonah · the sensor',
    if (game.trustOf('tess') >= 1) 'Tess · the code',
    if (game.trustOf('deacon') >= 1) 'Deacon · the photo',
    if (game.trustOf('mara') >= 1) 'Mara · the login',
  ];
  if (bits.isEmpty) return 'Trust ledger · earn their proof';
  return bits.join('  ·  ');
}

class _Meter extends StatelessWidget {
  const _Meter(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    final color = value < 0 ? HmColors.danger : value >= 2 ? HmColors.ok : HmColors.amber;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: monoStyle.copyWith(fontSize: 10, color: HmColors.textDim)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 14,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: value > i ? color : HmColors.hairline,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
