import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/glass.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import 'app_registry.dart';
import 'phone_shell.dart';
import 'widgets.dart';

/// Extra bottom inset so Skip / Next chrome does not cover puzzle controls.
const kObjectiveOverlayInsetCollapsed = 52.0;
const kObjectiveOverlayInsetExpanded = 56.0;

bool objectiveBarVisible(Interaction it, {required String route}) {
  if (route == '/messages' &&
      (it is ChoiceInteraction || it is TypingInteraction)) {
    return false;
  }
  return it is GoalInteraction ||
      it is ChoiceInteraction ||
      it is TypingInteraction ||
      it is MinigameInteraction;
}

double objectiveOverlayInset({required bool visible, required bool expanded}) {
  if (!visible) return 0;
  return expanded
      ? kObjectiveOverlayInsetExpanded
      : kObjectiveOverlayInsetCollapsed;
}

/// Bottom hint: a small Next chip expands the objective; Skip sits beside it
/// after three failed attempts. Tapping the expanded pill follows the next step.
class ObjectiveBar extends ConsumerWidget {
  const ObjectiveBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(storyEngineProvider);
    final it = session.interaction;
    String? text;
    VoidCallback? onTap;
    IconData icon = Icons.flag_rounded;

    final playerName = session.game.playerName;
    if (session.game.objective != null && it is GoalInteraction) {
      final obj = session.game.objective!;
      text = context.tr(obj.text, playerName: playerName);
      onTap = () => _navigateTo(obj.target);
    } else if (it is ChoiceInteraction) {
      final who = displayName(ref, it.thread);
      text = context.fmt('Reply to {name}', {'name': who});
      icon = Icons.reply_rounded;
      onTap = () => openApp('messages', arguments: it.thread);
    } else if (it is TypingInteraction) {
      final who = displayName(ref, it.from);
      text = context.fmt('{name} is typing…', {'name': who});
      icon = Icons.more_horiz_rounded;
      onTap = () => openApp('messages', arguments: it.thread);
    } else if (it is MinigameInteraction) {
      text = context.tr((it.node['title'] as String?) ?? 'Open the puzzle');
      icon = Icons.extension_rounded;
      onTap = () => pushShellRouteExclusive('/minigame', arguments: it);
    }

    final bottom = MediaQuery.paddingOf(context).bottom + 6;
    final showSkip =
        it is MinigameInteraction &&
        (session.game.fails[it.puzzleId] ?? 0) >= 3;

    return ValueListenableBuilder<String>(
      valueListenable: shellRouteListenable,
      builder: (context, route, _) {
        final visible = text != null && objectiveBarVisible(it, route: route);
        return ValueListenableBuilder<bool>(
          valueListenable: objectiveHintExpanded,
          builder: (context, expanded, _) {
            return Positioned(
              left: expanded ? 16 : null,
              right: 16,
              bottom: bottom,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: visible ? 1 : 0,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: expanded
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        if (showSkip && visible) ...[
                          ShellChipButton(
                            label: 'Skip',
                            onTap: () => _skipPuzzle(context, ref),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (expanded && visible)
                          Expanded(
                            child: _ObjectivePill(
                              text: text ?? '',
                              icon: icon,
                              onTap: () {
                                objectiveHintExpanded.value = false;
                                onTap?.call();
                              },
                            ),
                          )
                        else
                          ShellChipButton(
                            label: 'Next',
                            onTap: visible
                                ? () => objectiveHintExpanded.value = true
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _skipPuzzle(BuildContext context, WidgetRef ref) async {
    final ok = await showGlassConfirm(
      context: context,
      kicker: 'Puzzle',
      title: 'Skip?',
      body: 'You will move on, but this piece of proof will not count toward the ending.',
      cancelLabel: 'Keep trying',
      confirmLabel: 'Skip',
      destructive: true,
    );
    if (ok != true) return;
    shellNavigatorKey.currentState?.maybePop();
    ref.read(storyEngineProvider.notifier).completeMinigame(skipped: true);
  }

  void _navigateTo(Map<String, String> target) {
    if (target.containsKey('thread')) {
      openApp('messages', arguments: target['thread']);
    } else if (target.containsKey('photo')) {
      openApp('gallery', arguments: target['photo']);
    } else if (target.containsKey('voicemail')) {
      openApp('calls', arguments: target['voicemail']);
    } else if (target.containsKey('page')) {
      openApp('browser');
    } else if (target.containsKey('app')) {
      openApp(target['app']!);
    }
  }
}

class _ObjectivePill extends StatelessWidget {
  const _ObjectivePill({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: HmColors.surfaceRaised.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: HmColors.teal.withValues(alpha: 0.6)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: HmColors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: HmColors.text,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: HmColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top banner for diegetic notifications. Auto-dismisses; tap opens the app.
class NotificationBanner extends StatefulWidget {
  const NotificationBanner({super.key});
  @override
  State<NotificationBanner> createState() => NotificationBannerState();
}

class NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  AppNotification? _current;
  Timer? _hide;

  void show(AppNotification n) {
    _hide?.cancel();
    setState(() => _current = n);
    _ctrl.forward(from: 0);
    _hide = Timer(const Duration(milliseconds: 3400), dismiss);
  }

  void dismiss() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _current = null);
    });
  }

  String _playerName(BuildContext context) =>
      ProviderScope.containerOf(context)
          .read(storyEngineProvider)
          .game
          .playerName;

  @override
  void dispose() {
    _hide?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = _current;
    if (n == null) return const SizedBox.shrink();
    final app = phoneApps.any((a) => a.id == n.app) ? appOf(n.app) : null;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -1.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
          child: Dismissible(
            key: ValueKey(n),
            direction: DismissDirection.up,
            onDismissed: (_) => setState(() => _current = null),
            child: GlassCard(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(12),
              accent: true,
              onTap: () {
                dismiss();
                if (app != null) openApp(app.id);
              },
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: HmColors.tealDim.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      app?.icon ?? Icons.notifications,
                      color: HmColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(n.title, playerName: _playerName(context)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          context.tr(n.body, playerName: _playerName(context)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HmColors.textDim,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mirror's instability: RGB-split tears, scanlines, and an optional
/// ghost notification that appears for a moment and is gone.
class GlitchOverlay extends StatefulWidget {
  const GlitchOverlay({super.key});
  @override
  State<GlitchOverlay> createState() => GlitchOverlayState();
}

class GlitchOverlayState extends State<GlitchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _event = null);
        }
      });
  GlitchEvent? _event;
  final _rng = math.Random();

  void trigger(GlitchEvent e) {
    setState(() => _event = e);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    if (e == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            // Tears are strongest in the first third, then settle.
            final intensity = t < 0.35
                ? 1.0
                : math.max(0.0, 1 - (t - 0.35) / 0.4);
            final ghostVisible = e.ghostText != null && t > 0.15 && t < 0.62;
            return Stack(
              children: [
                CustomPaint(
                  painter: _TearPainter(
                    intensity: intensity,
                    seed: (t * 60).floor(),
                    rng: _rng,
                  ),
                ),
                if (ghostVisible)
                  Positioned(
                    top: 90,
                    left: 12,
                    right: 12,
                    child: Transform.translate(
                      offset: Offset(_rng.nextDouble() * 6 - 3, 0),
                      child: _GhostCard(
                        from: e.ghostFrom ?? 'Wren',
                        text: e.ghostText!,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.from, required this.text});
  final String from;
  final String text;
  @override
  Widget build(BuildContext context) {
    final playerName = ProviderScope.containerOf(context)
        .read(storyEngineProvider)
        .game
        .playerName;
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(-2, 0),
          child: _card(
            context,
            playerName,
            HmColors.glitchCyan.withValues(alpha: 0.35),
          ),
        ),
        Transform.translate(
          offset: const Offset(2, 0),
          child: _card(
            context,
            playerName,
            HmColors.glitchMagenta.withValues(alpha: 0.35),
          ),
        ),
        _card(context, playerName, null),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    String playerName,
    Color? tint,
  ) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint ?? HmColors.surfaceRaised.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tint == null ? HmColors.hairline : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_rounded, color: HmColors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(from, playerName: playerName),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: tint == null ? HmColors.text : Colors.transparent,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  context.tr(text, playerName: playerName),
                  style: TextStyle(
                    color: tint == null ? HmColors.text : Colors.transparent,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TearPainter extends CustomPainter {
  _TearPainter({
    required this.intensity,
    required this.seed,
    required this.rng,
  });
  final double intensity;
  final int seed;
  final math.Random rng;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final r = math.Random(seed);
    final bands = (6 * intensity).ceil();
    for (var i = 0; i < bands; i++) {
      final y = r.nextDouble() * size.height;
      final h = 2 + r.nextDouble() * 18 * intensity;
      final dx = (r.nextDouble() - 0.5) * 40 * intensity;
      canvas.drawRect(
        Rect.fromLTWH(dx, y, size.width, h),
        Paint()
          ..color = HmColors.glitchCyan.withValues(alpha: 0.10 * intensity),
      );
      canvas.drawRect(
        Rect.fromLTWH(-dx, y + h * 0.4, size.width, h * 0.6),
        Paint()
          ..color = HmColors.glitchMagenta.withValues(alpha: 0.10 * intensity),
      );
    }
    // Scanlines.
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.08 * intensity);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
  }

  @override
  bool shouldRepaint(covariant _TearPainter old) =>
      old.intensity != intensity || old.seed != seed;
}

