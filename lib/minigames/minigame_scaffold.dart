import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/glass.dart';
import '../core/notice.dart';
import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../features/shell/widgets.dart';
import '../l10n/l10n.dart';

/// Shared chrome and rules for every mini-game (bible §10):
/// three escalating hints, a skip after three failures, and a "Later" exit
/// that leaves the objective pill pointing back here.
class MinigameScaffold extends ConsumerWidget {
  const MinigameScaffold({
    super.key,
    required this.interaction,
    required this.child,
    this.brief,
    this.bottom,
    this.scroll = true,
  });

  final MinigameInteraction interaction;
  final Widget child;

  /// One or two sentences of in-fiction framing shown above the puzzle.
  final String? brief;
  final Widget? bottom;
  final bool scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(storyEngineProvider.notifier);
    final hintsUsed = ref.watch(storyEngineProvider
        .select((s) => s.game.hintsUsed[interaction.puzzleId] ?? 0));
    final hints = interaction.node.hints;
    final title = (interaction.node['title'] as String?) ?? 'Puzzle';
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (brief != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(context.tr(brief!),
                style: const TextStyle(color: HmColors.textDim, height: 1.45, fontSize: 14)),
          ),
        child,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: HmColors.bg,
        foregroundColor: HmColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        flexibleSpace: const ColoredBox(color: HmColors.bg),
        title: Text(context.tr(title),
            style: const TextStyle(
              fontSize: 17,
              color: HmColors.text,
              decoration: TextDecoration.none,
            )),
        leading: IconButton(
          tooltip: context.tr('Later'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (hints.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showHints(context, engine, hints, hintsUsed),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18, color: HmColors.amber),
              label: Text(context.fmt('Hint {used}/{total}', {
                'used': hintsUsed.clamp(0, hints.length),
                'total': hints.length,
              }),
                  style: const TextStyle(color: HmColors.amber)),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: scroll ? SingleChildScrollView(child: body) : body),
            ?bottom,
          ],
        ),
      ),
    );
  }

  void _showHints(BuildContext context, StoryEngine engine, List<String> hints, int used) {
    final reveal = (used + 1).clamp(1, hints.length);
    if (reveal > used) engine.useHint(interaction.puzzleId);
    showGlassSheet(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Hints'),
            for (var i = 0; i < reveal; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}  ', style: monoStyle.copyWith(color: HmColors.amber)),
                    Expanded(
                      child: Text(
                        c.tr(hints[i]),
                        style: const TextStyle(
                          height: 1.45,
                          color: HmColors.text,
                          fontSize: 15,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (reveal < hints.length)
              Text(c.tr('Open hints again for the next one.'),
                  style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
          ],
        ),
      ),
    );
  }
}

/// Success/failure plumbing shared by game widgets.
extension MinigameOutcome on WidgetRef {
  void minigameSuccess(BuildContext context, {String? message}) {
    final engine = read(storyEngineProvider.notifier);
    if (message != null) {
      showAppNotice(message, tone: AppNoticeTone.success);
    }
    Future.delayed(Duration(milliseconds: message == null ? 250 : 1100), () {
      if (!context.mounted) return;
      Navigator.of(context).maybePop();
      engine.completeMinigame();
    });
  }

  void minigameFail(BuildContext context, String puzzleId, String message) {
    read(storyEngineProvider.notifier).failMinigame(puzzleId);
    showAppNotice(message, tone: AppNoticeTone.error);
  }
}

/// A "Check" button row used by several games.
class CheckBar extends StatelessWidget {
  const CheckBar({super.key, required this.onCheck, this.label = 'Check', this.enabled = true, this.status});
  final VoidCallback onCheck;
  final String label;
  final bool enabled;
  final String? status;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            if (status != null)
              Expanded(child: Text(context.tr(status!), style: monoStyle.copyWith(color: HmColors.textDim, fontSize: 12))),
            ShellChipButton(label: label, onTap: enabled ? onCheck : null),
          ],
        ),
      );
}
