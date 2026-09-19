import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/photos.dart';
import '../core/theme.dart';
import '../engine/story_engine.dart';
import 'minigame_scaffold.dart';

/// Photo Zoom & Spot. config: {"photo": id, "required": [hotspot ids]}
/// Tapping within a hotspot radius reveals it; misses are not failures
/// (players are encouraged to look), but three far misses surface hints.
class PhotoSpotGame extends ConsumerStatefulWidget {
  const PhotoSpotGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<PhotoSpotGame> createState() => _PhotoSpotGameState();
}

class _PhotoSpotGameState extends ConsumerState<PhotoSpotGame> {
  final _found = <String>{};
  final _controller = TransformationController();
  int _misses = 0;
  String? _lastDetail;

  Photo get photo => photoOf(widget.interaction.node.config['photo'] as String);
  List<String> get required =>
      ((widget.interaction.node.config['required'] as List?) ?? photo.hotspots.map((h) => h.id).toList())
          .cast<String>();

  @override
  void initState() {
    super.initState();
    final flags = ref.read(storyEngineProvider).game.flags;
    for (final h in photo.hotspots) {
      if (flags.contains('spot_${photo.id}_${h.id}')) _found.add(h.id);
    }
  }

  void _tap(Offset scenePoint, Size imageSize) {
    final nx = scenePoint.dx / imageSize.width;
    final ny = scenePoint.dy / imageSize.height;
    Hotspot? hit;
    for (final h in photo.hotspots) {
      final d = Offset(h.dx - nx, (h.dy - ny) * (imageSize.height / imageSize.width));
      if (d.distance < 0.09) {
        hit = h;
        break;
      }
    }
    if (hit == null) {
      _misses++;
      if (_misses % 3 == 0) {
        ref.minigameFail(context, widget.interaction.puzzleId, 'Nothing there. Look at edges, reflections, lights.');
      }
      return;
    }
    if (_found.contains(hit.id)) {
      _detail(hit);
      return;
    }
    setState(() => _found.add(hit!.id));
    ref.read(storyEngineProvider.notifier).applyEffects({'flags': ['spot_${photo.id}_${hit.id}']});
    _detail(hit);
    if (required.every(_found.contains)) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) ref.minigameSuccess(context, message: 'Every detail examined.');
      });
    }
  }

  void _detail(Hotspot h) {
    setState(() => _lastDetail = '${h.label}: ${h.detail}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.interaction.node.config;
    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: cfg['brief'] as String? ?? 'Pinch to zoom. Tap anything that looks out of place.',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final id in required)
                  _SpotChip(
                    found: _found.contains(id),
                    label: _found.contains(id)
                        ? photo.hotspots.firstWhere((h) => h.id == id).label
                        : 'detail ${required.indexOf(id) + 1}',
                  ),
              ],
            ),
            if (_lastDetail != null) ...[
              const SizedBox(height: 12),
              Text(
                _lastDetail!,
                style: const TextStyle(
                  color: Color(0xFFF4F7F8),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      ),
      child: Expanded(
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = w / photo.aspect;
            final size = Size(w, h);
            return Center(
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _controller,
                  maxScale: 5,
                  child: GestureDetector(
                    onTapUp: (d) => _tap(d.localPosition, size),
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(photo.asset, fit: BoxFit.cover),
                          for (final hs in photo.hotspots)
                            if (_found.contains(hs.id))
                              Positioned(
                                left: hs.dx * w - 18,
                                top: hs.dy * h - 18,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: HmColors.amber, width: 2),
                                    boxShadow: [BoxShadow(color: HmColors.amber.withValues(alpha: 0.5), blurRadius: 12)],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SpotChip extends StatelessWidget {
  const _SpotChip({required this.found, required this.label});
  final bool found;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: found ? HmColors.ok.withValues(alpha: 0.7) : HmColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            found ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: found ? HmColors.ok : HmColors.teal,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: found ? HmColors.text : const Color(0xFFF4F7F8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
