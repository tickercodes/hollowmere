import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio.dart';
import 'core/theme.dart';
import 'core/whisper.dart';
import 'engine/story_engine.dart';
import 'features/shell/ending_screen.dart';
import 'features/shell/menu_screen.dart';
import 'features/shell/phone_shell.dart';

class HollowmereApp extends ConsumerWidget {
  const HollowmereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'The Hollowmere Files',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // MaterialApp's own DefaultTextStyle is the debug fallback (red type,
      // yellow double underline). Anything not sitting under a Scaffold/Material
      // - overlays, nested-navigator siblings, title cards - picks that up.
      // Pin a real style at the root so every screen inherits it.
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(
            inherit: false,
            color: HmColors.text,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
            debugLabel: 'hollowmere body',
          ),
          child: IconTheme(
            data: const IconThemeData(color: HmColors.text),
            child: Material(
              color: HmColors.bg,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerStatefulWidget {
  const _Root();
  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  String? _audioKey;

  @override
  void initState() {
    super.initState();
    // Route engine sound requests to the audio service for the app lifetime.
    final engine = ref.read(storyEngineProvider.notifier);
    final audio = ref.read(audioProvider);
    engine.sfx.listen(audio.sfx);
    engine.whispers.listen((id) => unawaited(audio.playVoice(id)));
    unawaited(audio.startMusic());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAudio(ref.read(storyEngineProvider).interaction);
    });
  }

  void _syncAudio(Interaction it) {
    final key = switch (it) {
      MenuInteraction() => 'menu',
      TitleInteraction(:final node) => 'title:${node.id}',
      SceneInteraction(:final node) => 'scene:${node.id}',
      EpisodeEndInteraction(:final node) => 'end:${node.id}',
      EndingInteraction(:final endingId) => 'ending:$endingId',
      _ => 'play',
    };
    if (key == _audioKey) return;
    _audioKey = key;
    final audio = ref.read(audioProvider);
    if (it is MenuInteraction) {
      unawaited(audio.setMood(MusicMood.menu));
    } else if (it is TitleInteraction ||
        it is SceneInteraction ||
        it is EpisodeEndInteraction) {
      unawaited(audio.setMood(MusicMood.scene));
    } else if (it is EndingInteraction) {
      unawaited(audio.setMood(MusicMood.ending));
    } else {
      unawaited(audio.setMood(MusicMood.play));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Interaction>(
      storyEngineProvider.select((s) => s.interaction),
      (prev, next) => _syncAudio(next),
    );
    final interaction =
        ref.watch(storyEngineProvider.select((s) => s.interaction));
    final Widget child = switch (interaction) {
      MenuInteraction() => const MenuScreen(),
      EndingInteraction(:final endingId) => EndingScreen(endingId: endingId),
      _ => const PhoneShell(),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
        ),
        const WhisperOverlay(),
      ],
    );
  }
}
