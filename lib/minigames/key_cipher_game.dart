import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../l10n/l10n.dart';
import 'logic/cipher.dart';
import 'minigame_scaffold.dart';

/// Thorne's terminal. The key is a sequence of marks, not a typed word.
/// config: {"ciphertext": "WRMLTAU", "answer": "TRAITOR",
///   "key": ["house","arch","gear"],
///   "marks": [{"id","glyph","letter","label"}, ...]}
class KeyCipherGame extends ConsumerStatefulWidget {
  const KeyCipherGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<KeyCipherGame> createState() => _KeyCipherGameState();
}

class _KeyCipherGameState extends ConsumerState<KeyCipherGame> {
  final List<String> _picked = [];

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  List<Map<String, dynamic>> get marks =>
      (cfg['marks'] as List).cast<Map<String, dynamic>>();
  List<String> get key => (cfg['key'] as List).cast<String>();
  String get ciphertext => cfg['ciphertext'] as String;

  Map<String, dynamic>? _mark(String id) {
    for (final m in marks) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  String get _keyLetters => [
        for (final id in _picked) _mark(id)?['letter'] as String? ?? '',
      ].join();

  String get _decoded =>
      _picked.isEmpty ? '' : Cipher.vigenere(ciphertext, _keyLetters);

  void _add(String id) {
    if (_picked.length >= key.length || _picked.contains(id)) return;
    setState(() => _picked.add(id));
  }

  void _undo() {
    if (_picked.isEmpty) return;
    setState(() => _picked.removeLast());
  }

  void _check() {
    final placed = _picked.join('|');
    if (placed == key.join('|')) {
      ref.minigameSuccess(context, message: 'The marks take.');
    } else {
      ref.minigameFail(
        context,
        widget.interaction.puzzleId,
        'The terminal rejects that key.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinigameScaffold(
      interaction: widget.interaction,
      brief: cfg['brief'] as String? ??
          'The back of the photo is the key. Set the marks in the order they were drawn.',
      bottom: CheckBar(
        onCheck: _check,
        enabled: _picked.length == key.length,
        label: 'Set the key',
        status: _picked.isEmpty ? 'key empty' : '${_picked.length} / ${key.length}',
      ),
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
                  Text(ciphertext,
                      style: const TextStyle(fontSize: 22, height: 1.6, letterSpacing: 4)),
                  const SizedBox(height: 12),
                  Text(
                    _decoded.isEmpty ? '— — —' : _decoded,
                    style: monoStyle.copyWith(
                      color: HmColors.teal,
                      fontSize: 15,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(context.tr('KEY'),
                style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim, letterSpacing: 2)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < key.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _slot(i)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _picked.isEmpty ? null : _undo,
                child: Text(context.tr('Undo last mark')),
              ),
            ),
            const SizedBox(height: 8),
            Text(context.tr('MARKS ON THE PHOTO'),
                style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim, letterSpacing: 2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in marks)
                  _MarkChip(
                    glyph: m['glyph'] as String,
                    label: m['label'] as String,
                    used: _picked.contains(m['id']),
                    onTap: () => _add(m['id'] as String),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final id = i < _picked.length ? _picked[i] : null;
    final mark = id == null ? null : _mark(id);
    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HmColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mark == null ? HmColors.hairline : HmColors.teal),
      ),
      child: mark == null
          ? Text('${i + 1}', style: monoStyle.copyWith(color: HmColors.textDim))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mark['glyph'] as String, style: const TextStyle(fontSize: 22)),
                Text(context.tr(mark['label'] as String),
                    style: monoStyle.copyWith(fontSize: 10, color: HmColors.textDim)),
              ],
            ),
    );
  }
}

class _MarkChip extends StatelessWidget {
  const _MarkChip({
    required this.glyph,
    required this.label,
    required this.used,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HmColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: used ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: used ? 0.35 : 1,
          child: Container(
            width: 108,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HmColors.hairline),
            ),
            child: Column(
              children: [
                Text(glyph, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(context.tr(label),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: HmColors.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
