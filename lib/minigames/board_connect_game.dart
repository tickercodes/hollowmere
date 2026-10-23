import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/characters.dart';
import '../content/evidence.dart';
import '../core/glass.dart';
import '../engine/game_state.dart';
import '../engine/story_engine.dart';
import '../l10n/l10n.dart';
import '../features/board/board_screen.dart';
import 'minigame_config.dart';
import 'minigame_scaffold.dart';

/// Suspect Board deduction lock. config: {"required": [["a","b"], ...]}
/// The player must connect every required pair; extra strings are allowed
/// (wrong theories are never punished) but the board only "clicks" when the
/// necessary links exist.
class BoardConnectGame extends ConsumerStatefulWidget {
  const BoardConnectGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<BoardConnectGame> createState() => _BoardConnectGameState();
}

class _BoardConnectGameState extends ConsumerState<BoardConnectGame> {
  String? _pending;

  List<String> get required => [
    for (final pair in MinigameConfig.boardRequired(widget.interaction.node.config))
      if (pair.length >= 2) GameState.linkKey(pair[0], pair[1]),
  ];

  void _tap(String id) {
    if (_pending == null) {
      setState(() => _pending = id);
      return;
    }
    if (_pending != id) {
      ref.read(storyEngineProvider.notifier).toggleLink(_pending!, id);
    }
    setState(() => _pending = null);
  }

  void _check() {
    final links = ref.read(storyEngineProvider).game.boardLinks;
    final missing = required.where((k) => !links.contains(k)).length;
    if (missing == 0) {
      ref.minigameSuccess(
        context,
        message: 'It fits. The board makes sense now.',
      );
    } else {
      ref.minigameFail(
        context,
        widget.interaction.puzzleId,
        L10nCatalog.format(
          missing == 1
              ? '{n} connection still missing.'
              : '{n} connections still missing.',
          {'n': missing},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final have = required.where(game.boardLinks.contains).length;
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: widget.interaction.node.config['brief'] as String? ?? 'Tap two pins to run a string between them. Connect what belongs together.',
      bottom: CheckBar(
        onCheck: _check,
        label: 'Does it hold?',
        status: context.fmt(
          _pending == null
              ? '{have} / {total} key connections · pick a pin'
              : '{have} / {total} key connections · pick another',
          {'have': have, 'total': required.length},
        ),
      ),
      child: Expanded(
        child: BoardCanvas(
          pins: {
            ...game.boardPins,
            for (final pair in MinigameConfig.boardRequired(widget.interaction.node.config))
              ...pair,
          },
          links: game.boardLinks,
          pending: _pending,
          onTapPin: _tap,
        ),
      ),
    );
  }
}

/// Final accusation. config: {"suspects": ["ardis","jonah",...]}
/// Locks the board and sets `accused_<id>`.
class AccuseGame extends ConsumerStatefulWidget {
  const AccuseGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<AccuseGame> createState() => _AccuseGameState();
}

class _AccuseGameState extends ConsumerState<AccuseGame> {
  String? _choice;

  List<String> get suspects =>
      (widget.interaction.node.config['suspects'] as List).cast<String>();

  Future<void> _confirm() async {
    final id = _choice;
    if (id == null) return;
    final ok = await showGlassConfirm(
      context: context,
      kicker: 'The board',
      title: 'Commit to this?',
      body: 'The board locks once you accuse. There is no taking it back.',
      cancelLabel: 'Not yet',
      confirmLabel: 'Accuse',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    ref.read(storyEngineProvider.notifier).applyEffects({
      'flags': ['accused_$id', 'board_locked'],
      'journal': 'You accused ${characterOf(id).name}.',
    });
    ref.minigameSuccess(context);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: widget.interaction.node.config['brief'] as String? ?? 'Tap the pin you are accusing. Everything you have gathered is behind this choice.',
      bottom: CheckBar(
        onCheck: _confirm,
        enabled: _choice != null,
        label: 'Accuse',
        status: _choice == null
            ? 'no one selected'
            : context.fmt('accusing · {name}', {
                'name':
                    boardPins[_choice!]?.label ?? characterOf(_choice!).name,
              }),
      ),
      child: Expanded(
        child: BoardCanvas(
          pins: game.boardPins,
          links: game.boardLinks,
          highlight: {?_choice},
          onTapPin: (id) {
            if (suspects.contains(id)) setState(() => _choice = id);
          },
        ),
      ),
    );
  }
}
