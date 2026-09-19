import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../shell/phone_shell.dart';
import '../shell/widgets.dart';

/// Wren's photo feed as mirrored. Deleted or edited posts show a cached
/// caption when the Social Feed Scrub mini-game has recovered it.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(storyEngineProvider.notifier).report({'app': 'feed'}));
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    return AppScaffold(
      title: 'Feed',
      subtitle: '@wren.calloway · hollowmere below',
      body: game.feed.isEmpty
          ? const EmptyHint('Feed has not synced.')
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: game.feed.length,
              itemBuilder: (context, i) => FeedCard(
                post: game.feed[i],
                showCached: game.has('cache_revealed_${game.feed[i].id}'),
              ),
            ),
    );
  }
}

class FeedCard extends ConsumerWidget {
  const FeedCard({super.key, required this.post, this.showCached = false, this.onTap});
  final FeedPost post;
  final bool showCached;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = post.image == null ? null : photoOf(post.image!);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Material(
          color: HmColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: HmColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ListTile(
              dense: true,
              leading: Avatar(post.author, size: 34),
              title: Text(displayName(ref, post.author),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(post.timeLabel,
                  style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
              trailing: post.deleted ? const Pill('deleted', color: HmColors.danger) : null,
            ),
            if (image != null)
              GestureDetector(
                onTap: onTap ?? () => openApp('gallery', arguments: image.id),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: post.deleted && !showCached
                      ? Container(
                          color: HmColors.surfaceRaised,
                          alignment: Alignment.center,
                          child: const Icon(Icons.hide_image_outlined, color: HmColors.textDim, size: 40),
                        )
                      : Image.asset(image.asset, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.deleted && !showCached ? '[post removed]' : post.text,
                      style: const TextStyle(height: 1.4)),
                  if (showCached && post.cachedText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HmColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: HmColors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CACHED · 16 DAYS AGO',
                              style: monoStyle.copyWith(fontSize: 10, color: HmColors.amber, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(post.cachedText!, style: const TextStyle(height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
