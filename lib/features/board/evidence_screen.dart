import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/evidence.dart';
import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../shell/phone_shell.dart';
import '../shell/widgets.dart';

/// Everything the player has established, grouped by episode.
class EvidenceScreen extends ConsumerWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final items = evidenceCatalog.values.where((e) => game.evidence.contains(e.id)).toList()
      ..sort((a, b) => a.episode.compareTo(b.episode));
    final total = evidenceCatalog.length;
    final byEpisode = <int, List<EvidenceItem>>{};
    for (final e in items) {
      byEpisode.putIfAbsent(e.episode, () => []).add(e);
    }
    return AppScaffold(
      title: 'Evidence',
      subtitle: '${items.length} of $total on file',
      body: items.isEmpty
          ? const EmptyHint('Nothing on file yet.', icon: Icons.folder_open_rounded)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final ep in byEpisode.keys) ...[
                  SectionLabel('Episode $ep'),
                  for (final e in byEpisode[ep]!)
                    GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      onTap: e.photo == null ? null : () => openApp('gallery', arguments: e.photo),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (e.photo != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(photoOf(e.photo!).asset,
                                  width: 64, height: 64, fit: BoxFit.cover),
                            )
                          else
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: HmColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.description_outlined, color: HmColors.teal),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(e.summary,
                                    style: const TextStyle(color: HmColors.textDim, fontSize: 13, height: 1.4)),
                              ],
                            ),
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
