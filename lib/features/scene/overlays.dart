import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';

/// Full-screen story beats layered above the phone: title cards, scenes
/// (location image + narration), and the end-of-episode card.
class StoryOverlays extends ConsumerWidget {
  const StoryOverlays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final it = ref.watch(storyEngineProvider.select((s) => s.interaction));
    final Widget? inner = switch (it) {
      TitleInteraction(:final node) => _TitleCard(
          title: node['title'] as String,
          subtitle: node['subtitle'] as String?,
          kicker: node['kicker'] as String?,
        ),
      SceneInteraction(:final node) => _SceneCard(node: node),
      EpisodeEndInteraction(:final node, :final episode) => _EpisodeEndCard(
          episodeTitle: context.fmt('Episode {n} - {title}', {
            'n': episode.number,
            'title': episode.title,
          }),
          teaser: node['teaser'] as String?,
          hasNext: node['next_episode'] != null,
        ),
      _ => null,
    };
    final overlayKey = switch (it) {
      TitleInteraction(:final node) => ValueKey('title:${node.id}'),
      SceneInteraction(:final node) => ValueKey('scene:${node.id}'),
      EpisodeEndInteraction(:final node) => ValueKey('end:${node.id}'),
      _ => const ValueKey('none'),
    };
    // Positioned.fill must stay a direct child of the phone-shell Stack.
    // AnimatedSwitcher wraps its child in FadeTransition - never put a
    // Positioned *inside* the switcher.
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: inner == null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: SizedBox.expand(
            key: overlayKey,
            child: inner,
          ),
        ),
      ),
    );
  }
}

class _TitleCard extends ConsumerWidget {
  const _TitleCard({required this.title, this.subtitle, this.kicker});
  final String title;
  final String? subtitle;
  final String? kicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(storyEngineProvider.notifier).dismissOverlay(),
      child: Material(
        color: HmColors.bg,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (kicker != null) ...[
                Text(context.tr(kicker!).toUpperCase(),
                    style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 3)),
                const SizedBox(height: 18),
              ],
              _FadeIn(
                child: Text(context.tr(title),
                    textAlign: TextAlign.center,
                    style: displayStyle.copyWith(fontSize: 30)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 14),
                _FadeIn(
                  delay: 500,
                  child: Text(context.tr(subtitle!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: HmColors.textDim, fontSize: 15, height: 1.5)),
                ),
              ],
              const SizedBox(height: 48),
              _FadeIn(
                delay: 1200,
                child: Text(context.tr('tap to continue'),
                    style: monoStyle.copyWith(color: HmColors.textDim, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneCard extends ConsumerStatefulWidget {
  const _SceneCard({required this.node});
  final dynamic node;
  @override
  ConsumerState<_SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends ConsumerState<_SceneCard> {
  int _line = 0;

  @override
  Widget build(BuildContext context) {
    final lines = (widget.node['lines'] as List).cast<String>();
    final image = widget.node['image'] as String?;
    final title = widget.node['title'] as String?;
    final last = _line >= lines.length - 1;

    return GestureDetector(
      onTap: () {
        if (last) {
          ref.read(storyEngineProvider.notifier).dismissOverlay();
        } else {
          setState(() => _line++);
        }
      },
      child: Material(
        color: HmColors.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.asset(photoOf(image).asset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0A0C0E), HmColors.bg],
                  stops: [0.3, 0.7, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(context.tr(title).toUpperCase(),
                          style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 3)),
                    const SizedBox(height: 14),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topLeft,
                      child: Text(
                        context.tr(lines[_line]),
                        key: ValueKey(_line),
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.55,
                          color: HmColors.text,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= _line ? HmColors.teal : HmColors.hairline,
                            ),
                          ),
                        const Spacer(),
                        Text(context.tr(last ? 'continue' : 'tap'),
                            style: monoStyle.copyWith(color: HmColors.textDim, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeEndCard extends ConsumerWidget {
  const _EpisodeEndCard({
    required this.episodeTitle,
    this.teaser,
    required this.hasNext,
  });
  final String episodeTitle;
  final String? teaser;
  final bool hasNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(storyEngineProvider.notifier);
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    return Material(
      color: HmColors.bg,
      child: Padding(
      padding: const EdgeInsets.all(32),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('END OF'), style: monoStyle.copyWith(color: HmColors.teal, letterSpacing: 3)),
            const SizedBox(height: 12),
            Text(episodeTitle, textAlign: TextAlign.center,
                style: displayStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(context.tr('evidence'), '${game.evidenceCount}'),
                _Stat(context.tr('hints'), '${game.hintsUsed.values.fold(0, (a, b) => a + b)}'),
                _Stat(context.tr('trust · J'), '${game.trustOf('jonah')}'),
                _Stat(context.tr('trust · D'), '${game.trustOf('deacon')}'),
              ],
            ),
            if (teaser != null) ...[
              const SizedBox(height: 36),
              Text(context.tr(teaser!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: HmColors.textDim, fontStyle: FontStyle.italic, height: 1.5)),
            ],
            const SizedBox(height: 48),
            FilledButton(
              onPressed: engine.dismissOverlay,
              child: Text(context.tr(hasNext ? 'Next episode' : 'Finish')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: engine.backToMenu,
              child: Text(context.tr('Back to menu'), style: const TextStyle(color: HmColors.textDim)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Text(value, style: displayStyle.copyWith(fontSize: 22)),
            Text(context.tr(label), style: monoStyle.copyWith(fontSize: 10, color: HmColors.textDim)),
          ],
        ),
      );
}

class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 900),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      );
}
