import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/photos.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import 'app_registry.dart';
import 'phone_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    final grid = phoneApps.where((a) => !a.dock).toList();
    final dock = phoneApps.where((a) => a.dock).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(wallpaperSam, fit: BoxFit.cover),
          // Wren's wallpaper bleeds through as the mirror stabilises.
          AnimatedOpacity(
            duration: const Duration(seconds: 2),
            opacity: (game.mirrorLevel * 0.18).clamp(0, 0.55),
            child: Image.asset(wallpaperWren, fit: BoxFit.cover),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        const _StatusBar(),
                        const SizedBox(height: 8),
                        _MirrorStatus(level: game.mirrorLevel),
                        const SizedBox(height: 8),
                        _HoursSinceRead(hours: game.hoursSinceRead, read: game.has('message_read')),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          child: GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 22,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                            children: [
                              for (final app in grid)
                                _AppIcon(
                                  app: app,
                                  unlocked: game.unlockedApps.contains(app.id),
                                  badge: _badgeFor(app.id, game),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: HmColors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: HmColors.hairline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final app in dock)
                                _AppIcon(app: app, unlocked: true, badge: 0, compact: true),
                            ],
                          ),
                        ),
                        if (game.sirenEndsAtMs != null) const SizedBox(height: 36),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(child: _SirenCountdown()),
          ),
        ],
      ),
    );
  }

  int _badgeFor(String appId, GameState game) {
    switch (appId) {
      case 'messages':
        return game.unreadThreads.length;
      case 'calls':
        return game.callLog
            .where((c) => c.voicemail != null && !game.has('heard_${c.id}'))
            .length;
      default:
        return 0;
    }
  }
}

class _StatusBar extends StatefulWidget {
  const _StatusBar();
  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          Text(now.format(context),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: HmColors.text,
                decoration: TextDecoration.none,
              )),
          const Spacer(),
          const Icon(Icons.signal_cellular_alt, size: 16),
          const SizedBox(width: 6),
          const Icon(Icons.wifi, size: 16),
          const SizedBox(width: 6),
          const Icon(Icons.battery_5_bar, size: 16),
        ],
      ),
    );
  }
}

class _MirrorStatus extends StatelessWidget {
  const _MirrorStatus({required this.level});
  final int level;
  @override
  Widget build(BuildContext context) {
    final labels = ['mirror: unstable', 'mirror: syncing', 'mirror: partial', 'mirror: stable'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HmColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HmColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: level >= 3 ? HmColors.ok : HmColors.amber,
            ),
          ),
          const SizedBox(width: 8),
          Text(context.fmt("Wren's phone · {status}", {'status': labels[level.clamp(0, 3)]}),
              style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim)),
        ],
      ),
    );
  }
}

/// Episode 6 countdown. Only the home screen shows it, just above the dock.
class _SirenCountdown extends ConsumerStatefulWidget {
  const _SirenCountdown();

  @override
  ConsumerState<_SirenCountdown> createState() => _SirenCountdownState();
}

class _SirenCountdownState extends ConsumerState<_SirenCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ends = ref.watch(
      storyEngineProvider.select((s) => s.game.sirenEndsAtMs),
    );
    if (ends == null) return const SizedBox.shrink();
    final left = Duration(
      milliseconds: (ends - DateTime.now().millisecondsSinceEpoch).clamp(
        0,
        1 << 30,
      ),
    );
    final h = left.inHours;
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: HmColors.surfaceRaised.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: HmColors.danger.withValues(alpha: 0.7)),
          ),
          child: Text(
            context.fmt('SIREN  {time}', {'time': '$h:$m:$s'}),
            style: monoStyle.copyWith(
              fontSize: 11,
              color: HmColors.danger,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoursSinceRead extends StatelessWidget {
  const _HoursSinceRead({required this.hours, required this.read});
  final int hours;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HmColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HmColors.hairline),
      ),
      child: Text(
        read
            ? context.tr('Last message · Read')
            : context.fmt('Hours since last read: {hours}', {'hours': hours}),
        style: monoStyle.copyWith(
          fontSize: 11,
          color: read ? HmColors.ok : HmColors.amber,
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.app,
    required this.unlocked,
    required this.badge,
    this.compact = false,
  });

  final PhoneApp app;
  final bool unlocked;
  final int badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 58.0;
    return GestureDetector(
      onTap: unlocked ? () => openApp(app.id) : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: HmColors.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(size * 0.28),
                    border: Border.all(color: HmColors.tealDim),
                    boxShadow: [
                      BoxShadow(
                        color: HmColors.teal.withValues(alpha: 0.08),
                        blurRadius: 16,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(unlocked ? app.icon : Icons.lock_outline,
                      color: HmColors.teal, size: size * 0.5),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: HmColors.amber,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$badge',
                          style: const TextStyle(
                              color: HmColors.bg,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.tr(app.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  color: HmColors.text,
                  decoration: TextDecoration.none,
                )),
          ],
        ),
      ),
    );
  }
}
