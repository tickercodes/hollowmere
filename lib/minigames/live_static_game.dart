import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../features/shell/widgets.dart';
import 'minigame_scaffold.dart';

/// Live Static (Episode 4). Messages from Wren arrive in real time and
/// self-delete; each gives a short window to reply. config:
/// {"from": "wren", "steps": [{"text": "...", "timer": 20,
///    "options": [{"text","effects"?}], "timeout_effects"?: {...}}]}
/// No fail state: silence is itself an answer the story remembers.
class LiveStaticGame extends ConsumerStatefulWidget {
  const LiveStaticGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<LiveStaticGame> createState() => _LiveStaticGameState();
}

class _LiveStaticGameState extends ConsumerState<LiveStaticGame> {
  int _step = -1;
  final _log = <(String from, String text, bool gone)>[];
  Timer? _tick;
  int _left = 0;
  bool _awaiting = false;

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  List<Map<String, dynamic>> get steps => (cfg['steps'] as List).cast<Map<String, dynamic>>();
  String get from => (cfg['from'] as String?) ?? 'wren';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), _nextStep);
  }

  void _nextStep() {
    _tick?.cancel();
    final next = _step + 1;
    if (next >= steps.length) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) ref.minigameSuccess(context);
      });
      return;
    }
    final s = steps[next];
    setState(() {
      _step = next;
      _log.add((from, s['text'] as String, false));
      _left = (s['timer'] as int?) ?? 20;
      _awaiting = true;
    });
    ref.read(storyEngineProvider.notifier).applyEffects({'flags': ['live_seen_${widget.interaction.puzzleId}_$next']});
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        _timeout(s);
      }
    });
  }

  void _timeout(Map<String, dynamic> s) {
    final fx = s['timeout_effects'] as Map<String, dynamic>?;
    if (fx != null) ref.read(storyEngineProvider.notifier).applyEffects(fx);
    setState(() {
      _awaiting = false;
      _log.add(('player', '(no reply in time)', false));
    });
    _vanishAndContinue();
  }

  void _reply(Map<String, dynamic> option) {
    _tick?.cancel();
    final fx = option['effects'] as Map<String, dynamic>?;
    if (fx != null) ref.read(storyEngineProvider.notifier).applyEffects(fx);
    setState(() {
      _awaiting = false;
      _log.add(('player', option['text'] as String, false));
    });
    _vanishAndContinue();
  }

  /// Her message is struck through a beat later - the mirror ate it.
  void _vanishAndContinue() {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _log.length; i++) {
          if (_log[i].$1 == from && !_log[i].$3) _log[i] = (_log[i].$1, _log[i].$2, true);
        }
      });
      Future.delayed(const Duration(milliseconds: 1600), _nextStep);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _step >= 0 && _step < steps.length ? steps[_step] : null;
    final options = _awaiting && s != null
        ? (s['options'] as List).cast<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: const BoxDecoration(
            color: HmColors.surface, border: Border(top: BorderSide(color: HmColors.hairline))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_awaiting) ...[
              LinearProgressIndicator(
                value: (_left / ((s?['timer'] as int?) ?? 20)).clamp(0, 1),
                color: _left <= 5 ? HmColors.danger : HmColors.glitchCyan,
                backgroundColor: HmColors.hairline,
              ),
              const SizedBox(height: 4),
              Text('signal holds for $_left s',
                  style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
              const SizedBox(height: 8),
            ],
            for (final o in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => _reply(o),
                  child: Text(o['text'] as String),
                ),
              ),
            if (!_awaiting)
              Text(_step + 1 >= steps.length ? 'signal lost' : 'waiting for signal…',
                  textAlign: TextAlign.center,
                  style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
          ],
        ),
      ),
      child: Expanded(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Avatar(from, size: 30),
                  const SizedBox(width: 8),
                  Text('LIVE · unstable', style: monoStyle.copyWith(color: HmColors.glitchCyan, letterSpacing: 2, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final (who, text, gone) in _log)
                    Align(
                      alignment: who == 'player' ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                        decoration: BoxDecoration(
                          color: gone
                              ? HmColors.glitchMagenta.withValues(alpha: 0.10)
                              : who == 'player'
                                  ? HmColors.bubbleOut
                                  : HmColors.bubbleIn,
                          borderRadius: BorderRadius.circular(16),
                          border: gone ? Border.all(color: HmColors.glitchMagenta.withValues(alpha: 0.5)) : null,
                        ),
                        child: Text(text,
                            style: TextStyle(
                              fontSize: 15,
                              color: gone ? HmColors.textDim : HmColors.text,
                              decoration: gone ? TextDecoration.lineThrough : null,
                              decorationColor: HmColors.glitchMagenta,
                            )),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
