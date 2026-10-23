import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets.dart';

/// "Wren's Library": the mirrored photo roll. Locked items render as blurred
/// tiles until the mirror stabilises enough to sync them.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key, this.initialPhoto});
  final String? initialPhoto;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initialPhoto;
    WidgetsBinding.instance.addPostFrameCallback(_report);
  }

  void _report([_]) {
    final engine = ref.read(storyEngineProvider.notifier);
    final p = _open;
    engine.report(p == null ? {'app': 'gallery'} : {'app': 'gallery', 'photo': p});
  }

  void _select(String? id) {
    setState(() => _open = id);
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(storyEngineProvider.select((s) => s.game.gallery));
    final open = _open;
    if (open != null) {
      return PhotoViewer(photoId: open, onBack: () => _select(null));
    }
    final total = 40;
    final unlocked = gallery.where((g) => !g.locked).length;
    return AppScaffold(
      title: "Wren's Library",
      subtitle: context.fmt('{found} of {total} items synced', {
        'found': unlocked,
        'total': total,
      }),
      body: gallery.isEmpty
          ? const EmptyHint('Nothing has synced from her library yet.',
              icon: Icons.cloud_off_rounded)
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
              itemCount: total,
              itemBuilder: (context, i) {
                if (i >= gallery.length) return const _LockedTile(seed: 0);
                final g = gallery[i];
                final photo = photoOf(g.photo);
                if (g.locked) return _LockedTile(seed: i + 1, photo: photo);
                return GestureDetector(
                  onTap: () => _select(g.photo),
                  child: Hero(
                    tag: 'photo:${g.photo}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(photo.asset, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _LockedTile extends StatelessWidget {
  const _LockedTile({required this.seed, this.photo});
  final int seed;
  final Photo? photo;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Image.asset(photo!.asset, fit: BoxFit.cover),
              )
            else
              Container(color: HmColors.surfaceRaised),
            Container(color: HmColors.bg.withValues(alpha: 0.45)),
            Center(
              child: Icon(
                photo != null ? Icons.sync_rounded : Icons.lock_outline_rounded,
                color: HmColors.textDim.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ],
        ),
      );
}

/// Full-screen zoomable photo with caption and fake EXIF.
class PhotoViewer extends ConsumerWidget {
  const PhotoViewer({super.key, required this.photoId, required this.onBack});
  final String photoId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = photoOf(photoId);
    final found = ref.watch(storyEngineProvider
        .select((s) => s.game.flags.where((f) => f.startsWith('spot_${photoId}_')).length));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        flexibleSpace: const ColoredBox(color: Colors.black),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: onBack),
        title: Text(context.tr(photo.caption), style: const TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: 'photo:$photoId',
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.asset(photo.asset, fit: BoxFit.contain)),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            color: HmColors.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(photo.meta), style: monoStyle.copyWith(color: HmColors.textDim)),
                if (photo.hotspots.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 16, color: HmColors.amber),
                      const SizedBox(width: 6),
                      Text(context.fmt('{found} / {total} details examined', {
                        'found': found,
                        'total': photo.hotspots.length,
                      }),
                          style: monoStyle.copyWith(fontSize: 11, color: HmColors.amber)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
