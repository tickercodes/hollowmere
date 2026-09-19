import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/voicemails.dart';
import '../core/notice.dart';
import '../core/theme.dart';
import '../engine/story_engine.dart';
import '../features/calls/calls_screen.dart';
import '../features/shell/widgets.dart';
import 'minigame_scaffold.dart';

/// Audio Forensics / Voicemail Match. config:
/// {"voicemail": "vm_wren_47s", "required": ["siren","bell","car_door"]}
/// Scrub the recording; press "Tag" when a distinct sound is playing.
class AudioTagGame extends ConsumerStatefulWidget {
  const AudioTagGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<AudioTagGame> createState() => _AudioTagGameState();
}

class _AudioTagGameState extends ConsumerState<AudioTagGame> {
  double _pos = 0;
  final _found = <String>{};

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  Voicemail get vm => voicemailOf(cfg['voicemail'] as String);
  List<String> get required =>
      ((cfg['required'] as List?) ?? vm.cues.map((c) => c.id).toList()).cast<String>();

  void _tag() {
    VoicemailCue? hit;
    for (final c in vm.cues) {
      if ((_pos - c.at).abs() <= 3.0 && _pos >= c.at - 0.5) {
        hit = c;
        break;
      }
    }
    if (hit == null) {
      ref.minigameFail(context, widget.interaction.puzzleId,
          'Nothing there at ${_pos.toStringAsFixed(0)}s. Move to where the line jumps.');
      return;
    }
    if (_found.contains(hit.id)) {
      showAppNotice('Already tagged: ${hit.label}');
      return;
    }
    setState(() => _found.add(hit!.id));
    showAppNotice('${hit.label} - ${hit.detail}', duration: const Duration(seconds: 4));
    if (required.every(_found.contains)) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) ref.minigameSuccess(context, message: 'Background tagged.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MinigameScaffold(
      interaction: widget.interaction,
      brief: cfg['brief'] as String? ??
          'Listen past her voice. Move to each background sound and mark it.',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text('${_found.length} / ${required.length} sounds tagged',
                  style: monoStyle.copyWith(color: HmColors.textDim, fontSize: 12)),
            ),
            ShellChipButton(label: 'Tag this sound', onTap: _tag),
          ],
        ),
      ),
      child: Column(
        children: [
          VoicemailPlayer(
            voicemailId: vm.id,
            onPosition: (s) => setState(() => _pos = s),
            markers: [for (final c in vm.cues) if (_found.contains(c.id)) c.at],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final id in required)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HmColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _found.contains(id) ? HmColors.amber : HmColors.hairline),
                    ),
                    child: _found.contains(id)
                        ? Builder(builder: (_) {
                            final c = vm.cues.firstWhere((c) => c.id == id);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c.label} · ${c.at.toStringAsFixed(0)}s',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: HmColors.amber)),
                                const SizedBox(height: 4),
                                Text(c.detail, style: const TextStyle(color: HmColors.textDim, fontSize: 13, height: 1.4)),
                              ],
                            );
                          })
                        : Row(
                            children: [
                              const Icon(Icons.graphic_eq_rounded, color: HmColors.textDim, size: 18),
                              const SizedBox(width: 10),
                              Text('unidentified sound', style: monoStyle.copyWith(color: HmColors.textDim)),
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
