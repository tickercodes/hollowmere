import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio.dart';
import '../../core/glass.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets.dart';
import 'language_picker.dart';

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
          const SectionLabel('Language'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: Text(context.tr('Language')),
              subtitle: Text(
                ref.watch(localeProvider).label,
                style: const TextStyle(color: HmColors.textDim),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLanguagePicker(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Pacing'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.fmt('Typing speed · {speed}', {'speed': _speedLabel(game.textSpeed)})),
                Row(
                  children: [
                    Text(context.tr('Slow'),
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
                    Text(context.tr('Instant'),
                        style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
                  ],
                ),
                Text(
                  context.tr('You can always tap the screen to skip a typing indicator.'),
                  style: const TextStyle(color: HmColors.textDim, fontSize: 12),
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
              title: Text(context.tr('Sound effects')),
              subtitle: Text(context.tr('Voicemails always play.'), style: const TextStyle(color: HmColors.textDim)),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: audio.voicesEnabled,
              onChanged: (v) => setState(() => audio.setVoicesEnabled(v)),
              title: Text(context.tr('Mysterious voices')),
              subtitle: Text(
                context.tr('Only at the matching story beat. Off the rest of the time.'),
                style: const TextStyle(color: HmColors.textDim),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.fmt('Music intensity · {level}', {'level': _musicLabel(audio.musicIntensity)})),
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
                Text(
                  context.tr('A mystery score under the phone. Ducks when a voicemail or voice plays.'),
                  style: const TextStyle(color: HmColors.textDim, fontSize: 12),
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
                  title: Text(context.tr('Back to main menu')),
                  subtitle: Text(context.tr('Progress is saved automatically.'), style: const TextStyle(color: HmColors.textDim)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: engine.backToMenu,
                ),
                const Divider(height: 1, color: HmColors.hairline),
                ListTile(
                  title: Text(context.tr('Erase all progress'), style: const TextStyle(color: HmColors.danger)),
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
          const SizedBox(height: 12),
          const SectionLabel('Credits'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: Text(context.tr('Audio credits')),
              subtitle: Text(
                context.tr('Internet music; story whispers; Mixkit radio.'),
                style: const TextStyle(color: HmColors.textDim),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _audioCredits(context),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(context.tr('THE HOLLOWMERE FILES · v0.1'),
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

  void _audioCredits(BuildContext context) {
    showGlassSheet(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.tr('AUDIO'),
                style: monoStyle.copyWith(
                    color: HmColors.teal, letterSpacing: 2.4, fontSize: 11)),
            const SizedBox(height: 12),
            Text(
              c.tr(
                'Menu: Solo Piano 4 - Tozan (CC0)\n'
                'Investigation: Piano Horror - Francisco Alvear (Mixkit)\n'
                'Scenes: GoshtPiano2 - Kilua Boy (CC0)\n'
                'Endings: Echoes - Andrew Ev (Mixkit)\n'
                '\n'
                'Voices: story lines, same placeholder voices as the voicemails\n'
                'Radio static: Mixkit horror SFX\n'
                '\n'
                'Full source list: assets/audio/ATTRIBUTION.md',
              ),
              style: const TextStyle(color: HmColors.text, height: 1.45, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
