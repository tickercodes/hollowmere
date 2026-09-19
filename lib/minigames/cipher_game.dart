import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import 'logic/cipher.dart';
import 'minigame_scaffold.dart';

/// Messenger Decode. config:
/// {"cipher": "🌊🔑…", "answer": "LOCKER 14 IF I GO QUIET",
///  "legend": {"🌊":"L", ...} (symbols the player already knows),
///  "unknown": ["🔑", ...] (symbols they must infer)}
class CipherGame extends ConsumerStatefulWidget {
  const CipherGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<CipherGame> createState() => _CipherGameState();
}

class _CipherGameState extends ConsumerState<CipherGame> {
  final _input = TextEditingController();
  final _guesses = <String, String>{};

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  Map<String, String> get legend => Map<String, String>.from(cfg['legend'] as Map);
  List<String> get unknown => ((cfg['unknown'] as List?) ?? const []).cast<String>();
  String get cipher => cfg['cipher'] as String;

  String get partial {
    final map = {...legend, ..._guesses};
    return Cipher.decode(cipher, map);
  }

  void _check() {
    if (Cipher.matches(_input.text, cfg['answer'] as String)) {
      ref.minigameSuccess(context, message: 'Decoded.');
    } else {
      ref.minigameFail(context, widget.interaction.puzzleId, 'That is not what she wrote.');
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MinigameScaffold(
      interaction: widget.interaction,
      brief: cfg['brief'] as String? ??
          'Their code swaps letters for symbols. You know some of them from her old texts. Work out the rest.',
      bottom: CheckBar(onCheck: _check, label: 'Send decoded'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HmColors.bubbleIn,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cipher, style: const TextStyle(fontSize: 22, height: 1.6, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(partial, style: monoStyle.copyWith(color: HmColors.teal, fontSize: 15, letterSpacing: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('KNOWN', style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim, letterSpacing: 2)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in legend.entries)
                  Chip(
                    label: Text('${e.key} = ${e.value}', style: const TextStyle(fontSize: 14)),
                    backgroundColor: HmColors.surfaceRaised,
                    side: const BorderSide(color: HmColors.hairline),
                  ),
              ],
            ),
            if (unknown.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('YOUR GUESSES', style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim, letterSpacing: 2)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in unknown)
                    SizedBox(
                      width: 96,
                      child: TextField(
                        maxLength: 1,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: HmColors.text,
                          decoration: TextDecoration.none,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          prefixText: '$s = ',
                          isDense: true,
                          filled: true,
                          fillColor: HmColors.surfaceRaised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (v) => setState(() {
                          if (v.isEmpty) {
                            _guesses.remove(s);
                          } else {
                            _guesses[s] = v.toUpperCase();
                          }
                        }),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: _input,
              textCapitalization: TextCapitalization.characters,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              style: const TextStyle(
                color: HmColors.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                labelText: 'Full decoded message',
                filled: true,
                fillColor: HmColors.surfaceRaised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _check(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
