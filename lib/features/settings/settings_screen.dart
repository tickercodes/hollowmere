import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio.dart';
import '../../core/glass.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../shell/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final engine = ref.read(storyEngineProvider.notifier);
    final audio = ref.read(audioProvider);
    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionLabel('Pacing'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Typing speed · ${_speedLabel(game.textSpeed)}'),
                Row(
                  children: [
                    Text('Slow',
                        style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                    Expanded(
                      child: Slider(
                        value: (1.6 - game.textSpeed).clamp(0, 1.6),
                        min: 0.0,
                        max: 1.6,
                        divisions: 8,
                        onChanged: (v) => engine.setTextSpeed(1.6 - v),
                      ),
                    ),
                    Text('Instant',
                        style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                  ],
                ),
                const Text(
                  'You can always tap the screen to skip a typing indicator.',
                  style: TextStyle(color: HmColors.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Sound'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: audio.enabled,
              onChanged: (v) => setState(() => audio.setEnabled(v)),
              title: const Text('Sound effects'),
              subtitle: const Text('Voicemails always play.', style: TextStyle(color: HmColors.textDim)),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Music intensity · ${_musicLabel(audio.musicIntensity)}'),
                Slider(
                  value: audio.musicIntensity,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  onChanged: (v) {
                    audio.setMusicIntensity(v);
                    setState(() {});
                  },
                ),
                const Text(
                  'A low drone under the phone. Ducks when a voicemail plays.',
                  style: TextStyle(color: HmColors.textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Investigation'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Back to main menu'),
                  subtitle: const Text('Progress is saved automatically.', style: TextStyle(color: HmColors.textDim)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: engine.backToMenu,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Erase all progress', style: TextStyle(color: HmColors.danger)),
                  trailing: const Icon(Icons.delete_outline, color: HmColors.danger),
                  onTap: () async {
                    final ok = await showGlassConfirm(
                      context: context,
                      kicker: 'Settings',
                      title: 'Erase everything?',
                      body: 'Evidence, board, trust and episode progress will be lost.',
                      cancelLabel: 'Keep it',
                      confirmLabel: 'Erase',
                      destructive: true,
                    );
                    if (ok == true) await engine.resetProgress();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('THE HOLLOWMERE FILES · v0.1',
                style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  String _speedLabel(double v) {
    if (v == 0) return 'instant';
    if (v < 0.7) return 'fast';
    if (v <= 1.0) return 'normal';
    return 'slow';
  }

  String _musicLabel(double v) {
    if (v == 0) return 'off';
    if (v <= 0.2) return 'whisper';
    if (v <= 0.4) return 'low';
    if (v <= 0.7) return 'medium';
    return 'high';
  }
}
