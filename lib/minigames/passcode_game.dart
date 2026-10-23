import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../engine/story_engine.dart';
import 'minigame_scaffold.dart';

/// Passcode Cracker. config: {"answer": "2219", "clue": "...", "photo"?: id}
class PasscodeGame extends ConsumerStatefulWidget {
  const PasscodeGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<PasscodeGame> createState() => _PasscodeGameState();
}

class _PasscodeGameState extends ConsumerState<PasscodeGame> {
  String _entry = '';
  bool _shake = false;

  String get answer => widget.interaction.node.config['answer'] as String;

  void _press(String d) {
    if (_entry.length >= answer.length) return;
    setState(() => _entry += d);
    if (_entry.length == answer.length) _check();
  }

  Future<void> _check() async {
    if (_entry == answer) {
      ref.minigameSuccess(context, message: 'Unlocked.');
      return;
    }
    setState(() => _shake = true);
    ref.minigameFail(context, widget.interaction.puzzleId, 'Wrong passcode.');
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _entry = '';
        _shake = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.interaction.node.config;
    return MinigameScaffold(
      interaction: widget.interaction,
      brief: cfg['clue'] as String?,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.lock_outline_rounded, color: HmColors.teal, size: 36),
          const SizedBox(height: 8),
          Text(context.tr((cfg['label'] as String?) ?? 'Enter passcode'),
              style: const TextStyle(color: HmColors.textDim)),
          const SizedBox(height: 22),
          AnimatedSlide(
            duration: const Duration(milliseconds: 80),
            offset: _shake ? const Offset(0.03, 0) : Offset.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < answer.length; i++)
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _entry.length
                          ? (_shake ? HmColors.danger : HmColors.teal)
                          : Colors.transparent,
                      border: Border.all(color: _shake ? HmColors.danger : HmColors.teal, width: 1.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
            _KeyRow(keys: row, onPress: _press),
          _KeyRow(keys: const ['', '0', '⌫'], onPress: (k) {
            if (k == '⌫') {
              setState(() => _entry = _entry.isEmpty ? '' : _entry.substring(0, _entry.length - 1));
            } else if (k.isNotEmpty) {
              _press(k);
            }
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.keys, required this.onPress});
  final List<String> keys;
  final ValueChanged<String> onPress;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final k in keys)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: k.isEmpty
                    ? const SizedBox(width: 74, height: 74)
                    : Material(
                        color: HmColors.surfaceRaised,
                        shape: const CircleBorder(side: BorderSide(color: HmColors.hairline)),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onPress(k),
                          child: SizedBox(
                            width: 74,
                            height: 74,
                            child: Center(
                              child: Text(k,
                                  style: TextStyle(
                                      fontSize: k == '⌫' ? 22 : 28, fontWeight: FontWeight.w300)),
                            ),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      );
}
