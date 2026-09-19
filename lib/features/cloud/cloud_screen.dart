import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../shell/widgets.dart';

/// The app Sam never installed. Shows mirror sync status and, once the story
/// reveals it, the pairing record that proves Wren connected on purpose.
class CloudScreen extends ConsumerStatefulWidget {
  const CloudScreen({super.key});
  @override
  ConsumerState<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends ConsumerState<CloudScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(storyEngineProvider.notifier).report({'app': 'cloud'}));
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final level = game.mirrorLevel;
    final synced = game.gallery.where((g) => !g.locked).length;
    final showPairing = game.has('cloud_pairing_visible');
    final labels = ['unstable', 'syncing', 'partial', 'stable'];

    return AppScaffold(
      title: 'Cloud Backup',
      subtitle: "Library: Wren's Library",
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GlassCard(
            accent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, color: HmColors.teal),
                    const SizedBox(width: 10),
                    Text('Mirror ${labels[level.clamp(0, 3)]}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (level / 3).clamp(0.05, 1),
                  color: HmColors.teal,
                  backgroundColor: HmColors.hairline,
                ),
                const SizedBox(height: 10),
                Text(
                  'This phone is getting files from Wren\'s phone. '
                  'Photos: $synced synced. Messages: ${game.threads.length} threads. '
                  'Calls: ${game.callLog.length} entries.',
                  style: const TextStyle(color: HmColors.textDim, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 10),
                Text('you cannot stop this', style: monoStyle.copyWith(fontSize: 11, color: HmColors.amber)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Account'),
          const _Row('Library owner', 'wren.calloway'),
          const _Row('Owner device', 'Wren\'s phone · last sync unknown'),
          _Row('This device', '${game.playerName}\'s phone'),
          const SizedBox(height: 12),
          const SectionLabel('Paired devices'),
          if (!showPairing)
            const _Row('-', 'Device list hidden while the link is weak')
          else ...[
            const _Row('Device 1', 'Wren\'s phone (owner)'),
            GlassCard(
              accent: true,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device 2 · ${game.playerName.toUpperCase()}-COTTAGE-WIFI',
                      style: monoStyle.copyWith(color: HmColors.teal)),
                  const SizedBox(height: 6),
                  Text('Linked 11 days ago · 11:52 PM\nHow: your home wifi. She said yes.',
                      style: monoStyle.copyWith(fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('Five minutes after your message. From inside your house.',
                      style: TextStyle(color: HmColors.textDim, fontSize: 13)),
                ],
              ),
            ),
          ],
          if (game.has('saw_second_viewer')) ...[
            const SizedBox(height: 12),
            const SectionLabel('Viewers'),
            GlassCard(
              accent: true,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('M. ELLISON', style: monoStyle.copyWith(color: HmColors.amber)),
                  const SizedBox(height: 6),
                  Text('Plan: shared backup\nNetwork: RESERVOIR-AUTH-STAFF',
                      style: monoStyle.copyWith(fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    game.has('mara_gave_login')
                        ? 'Signed in as Wren\'s girlfriend. It was her password. Not her.'
                        : 'Active recently. The shared plan has another reader.',
                    style: const TextStyle(color: HmColors.textDim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.k, this.v);
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(color: HmColors.textDim))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
