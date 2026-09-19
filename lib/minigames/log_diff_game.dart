import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../features/calls/calls_screen.dart';
import 'minigame_scaffold.dart';

/// Log Discrepancy. config:
/// {"left_title": "Official Release Log", "right_title": "Dock sensor",
///  "rows": [{"time": "11th 06:00", "left": "release", "right": "level -0.4 m", "mismatch": false}, ...]}
/// Mark every row where the two sources disagree.
class LogDiffGame extends ConsumerStatefulWidget {
  const LogDiffGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<LogDiffGame> createState() => _LogDiffGameState();
}

class _LogDiffGameState extends ConsumerState<LogDiffGame> {
  final _marked = <int>{};

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  List<Map<String, dynamic>> get rows => (cfg['rows'] as List).cast<Map<String, dynamic>>();

  void _check() {
    final answer = {for (var i = 0; i < rows.length; i++) if (rows[i]['mismatch'] == true) i};
    if (_marked.length == answer.length && _marked.containsAll(answer)) {
      ref.minigameSuccess(context, message: 'Every discrepancy marked.');
    } else {
      final wrong = _marked.difference(answer).length;
      final missed = answer.difference(_marked).length;
      ref.minigameFail(context, widget.interaction.puzzleId,
          '${wrong > 0 ? '$wrong marked rows agree. ' : ''}${missed > 0 ? '$missed disagreement${missed == 1 ? '' : 's'} not marked.' : ''}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: cfg['brief'] as String? ?? 'Two records of the same nights. Mark every row where they do not match.',
      bottom: CheckBar(onCheck: _check, status: '${_marked.length} marked'),
      child: Expanded(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  const SizedBox(width: 92),
                  Expanded(child: Text((cfg['left_title'] as String?) ?? 'Official', style: monoStyle.copyWith(fontSize: 11, color: HmColors.amber))),
                  Expanded(child: Text((cfg['right_title'] as String?) ?? 'Sensor', style: monoStyle.copyWith(fontSize: 11, color: HmColors.teal))),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final marked = _marked.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() => marked ? _marked.remove(i) : _marked.add(i)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: marked ? HmColors.danger.withValues(alpha: 0.12) : HmColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: marked ? HmColors.danger : HmColors.hairline),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 84, child: Text(r['time'] as String, style: monoStyle.copyWith(fontSize: 12))),
                          Expanded(child: Text(r['left'] as String, style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text(r['right'] as String, style: const TextStyle(fontSize: 13))),
                          SizedBox(
                            width: 36,
                            child: Icon(marked ? Icons.flag_rounded : Icons.flag_outlined,
                                color: marked ? HmColors.danger : HmColors.textDim, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Voicemail Recording Match. config:
/// {"clips": [{"voicemail": "vm_unknown", "answer": "deacon"}], "options": ["deacon","jonah","ardis"]}
/// Identify who left each distorted message from voice and background cues.
class VoiceMatchGame extends ConsumerStatefulWidget {
  const VoiceMatchGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<VoiceMatchGame> createState() => _VoiceMatchGameState();
}

class _VoiceMatchGameState extends ConsumerState<VoiceMatchGame> {
  final _picks = <String, String>{};

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  List<Map<String, dynamic>> get clips => (cfg['clips'] as List).cast<Map<String, dynamic>>();
  List<String> get options => (cfg['options'] as List).cast<String>();

  void _check() {
    var right = 0;
    for (final c in clips) {
      if (_picks[c['voicemail']] == c['answer']) right++;
    }
    if (right == clips.length) {
      ref.minigameSuccess(context, message: 'Voices matched.');
    } else {
      ref.minigameFail(context, widget.interaction.puzzleId, '$right of ${clips.length} correct. Listen to what is behind the voice.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinigameScaffold(
      interaction: widget.interaction,
      brief: cfg['brief'] as String? ?? 'Match each recording to the person who left it. Background noise tells you where they were.',
      bottom: CheckBar(onCheck: _check, enabled: _picks.length == clips.length),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (final c in clips)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    _ClipPlayer(voicemailId: c['voicemail'] as String, obscured: true),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final o in options)
                          ChoiceChip(
                            label: Text(_labelFor(o)),
                            selected: _picks[c['voicemail']] == o,
                            selectedColor: HmColors.tealDim,
                            onSelected: (_) => setState(() => _picks[c['voicemail'] as String] = o),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String id) => switch (id) {
        'deacon' => 'Deacon Moss',
        'jonah' => 'Jonah Hale',
        'ardis' => 'Ardis Locke',
        'mara' => 'Mara Ellison',
        'tess' => 'Tess Quinn',
        _ => id,
      };
}

class _ClipPlayer extends StatelessWidget {
  const _ClipPlayer({required this.voicemailId, this.obscured = false});
  final String voicemailId;
  final bool obscured;

  @override
  Widget build(BuildContext context) => VoicemailPlayer(
        key: ValueKey('clip:$voicemailId'),
        voicemailId: voicemailId,
        compact: true,
        obscureCaller: obscured,
      );
}
