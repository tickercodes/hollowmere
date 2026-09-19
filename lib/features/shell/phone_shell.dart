import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notice.dart';
import '../../core/theme.dart';
import '../../engine/story_engine.dart';
import '../board/board_screen.dart';
import '../board/evidence_screen.dart';
import '../browser/browser_screen.dart';
import '../calls/call_screen.dart';
import '../calls/calls_screen.dart';
import '../cloud/cloud_screen.dart';
import '../feed/feed_screen.dart';
import '../gallery/gallery_screen.dart';
import '../messenger/messenger_screen.dart';
import '../notes/notes_screen.dart';
import '../scene/overlays.dart';
import '../settings/settings_screen.dart';
import '../../minigames/minigame_router.dart';
import 'home_screen.dart';
import 'overlays.dart';

final shellNavigatorKey = GlobalKey<NavigatorState>();

/// Current route inside the phone (e.g. `/messages`). Used to hide chrome
/// that would otherwise sit on top of an open thread.
final shellRouteListenable = ValueNotifier<String>('/');

/// Whether the objective hint is expanded from the info icon into the full bar.
final objectiveHintExpanded = ValueNotifier<bool>(false);

class _ShellRouteObserver extends NavigatorObserver {
  final List<String> stack = [];

  void _syncTop() {
    final name = stack.isEmpty ? '/' : stack.last;
    if (shellRouteListenable.value != name) {
      shellRouteListenable.value = name;
    }
    if (objectiveHintExpanded.value) objectiveHintExpanded.value = false;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) stack.add(name);
    _syncTop();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (stack.isNotEmpty) stack.removeLast();
    _syncTop();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (stack.isNotEmpty) stack.removeLast();
    final name = newRoute?.settings.name;
    if (name != null) stack.add(name);
    _syncTop();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      final i = stack.lastIndexOf(name);
      if (i >= 0) stack.removeAt(i);
    }
    _syncTop();
  }
}

final _shellRouteObserver = _ShellRouteObserver();

/// Push [name] only if it is not already the top route. If a copy is already
/// in the stack, pop back to it instead of stacking another.
void pushShellRouteExclusive(String name, {Object? arguments}) {
  final nav = shellNavigatorKey.currentState;
  if (nav == null) return;
  final stack = _shellRouteObserver.stack;
  if (stack.isNotEmpty && stack.last == name) return;
  if (stack.contains(name)) {
    nav.popUntil((r) => r.settings.name == name || r.isFirst);
    return;
  }
  nav.pushNamed(name, arguments: arguments);
}

/// Opens an app inside the phone, popping back to home first so the stack
/// never grows unbounded. `arguments` is app-specific (e.g. a thread id).
void openApp(String appId, {Object? arguments}) {
  final nav = shellNavigatorKey.currentState;
  if (nav == null) return;
  nav.popUntil((r) => r.isFirst);
  nav.pushNamed('/$appId', arguments: arguments);
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  final args = settings.arguments;
  Widget page;
  switch (settings.name) {
    case '/':
      page = const HomeScreen();
    case '/messages':
      page = MessengerScreen(initialThread: args as String?);
    case '/calls':
      page = CallsScreen(initialVoicemail: args as String?);
    case '/gallery':
      page = GalleryScreen(initialPhoto: args as String?);
    case '/browser':
      page = BrowserScreen(initialPage: args as String?);
    case '/cloud':
      page = const CloudScreen();
    case '/notes':
      page = const NotesScreen();
    case '/feed':
      page = const FeedScreen();
    case '/board':
      page = const BoardScreen();
    case '/evidence':
      page = const EvidenceScreen();
    case '/journal':
      page = const JournalScreen();
    case '/settings':
      page = const SettingsScreen();
    case '/minigame':
      page = MinigameRouter(interaction: args as MinigameInteraction);
    case '/call':
      page = CallScreen(interaction: args as CallInteraction);
    default:
      page = const HomeScreen();
  }
  final fullscreen = settings.name == '/minigame' || settings.name == '/call';
  return PageRouteBuilder(
    settings: settings,
    fullscreenDialog: fullscreen,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

class PhoneShell extends ConsumerStatefulWidget {
  const PhoneShell({super.key});
  @override
  ConsumerState<PhoneShell> createState() => _PhoneShellState();
}

class _PhoneShellState extends ConsumerState<PhoneShell> {
  StreamSubscription? _glitchSub;
  StreamSubscription? _notifSub;
  final _bannerKey = GlobalKey<NotificationBannerState>();
  final _glitchKey = GlobalKey<GlitchOverlayState>();
  String? _pushedFor;

  @override
  void initState() {
    super.initState();
    shellRouteListenable.value = '/';
    final engine = ref.read(storyEngineProvider.notifier);
    _glitchSub = engine.glitches.listen((g) => _glitchKey.currentState?.trigger(g));
    _notifSub = engine.notifications.listen((n) => _bannerKey.currentState?.show(n));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncRoutes(ref.read(storyEngineProvider).interaction);
    });
  }

  @override
  void dispose() {
    _glitchSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  /// Full-screen interactions (mini-games, calls) are opened once, never stacked.
  void _syncRoutes(Interaction it) {
    final key = switch (it) {
      MinigameInteraction(:final node) => 'mg:${node.id}',
      CallInteraction(:final node) => 'call:${node.id}',
      _ => null,
    };
    if (key == null) {
      _pushedFor = null;
      return;
    }
    if (key == _pushedFor) return;
    _pushedFor = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pushedFor != key) return;
      if (it is MinigameInteraction) {
        pushShellRouteExclusive('/minigame', arguments: it);
      } else if (it is CallInteraction) {
        pushShellRouteExclusive('/call', arguments: it);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Interaction>(
      storyEngineProvider.select((s) => s.interaction),
      (prev, next) => _syncRoutes(next),
    );
    final interaction = ref.watch(storyEngineProvider.select((s) => s.interaction));
    final engine = ref.read(storyEngineProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        final nav = shellNavigatorKey.currentState;
        if (nav != null && nav.canPop()) nav.pop();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (interaction is TypingInteraction) engine.skip();
        },
        child: Material(
          color: HmColors.bg,
          child: Stack(
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([
                  shellRouteListenable,
                  objectiveHintExpanded,
                ]),
                builder: (context, child) {
                  final media = MediaQuery.of(context);
                  final extra = objectiveOverlayInset(
                    visible: objectiveBarVisible(interaction,
                        route: shellRouteListenable.value),
                    expanded: objectiveHintExpanded.value,
                  );
                  return MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(
                          bottom: media.padding.bottom + extra),
                    ),
                    child: child!,
                  );
                },
                child: Navigator(
                  key: shellNavigatorKey,
                  initialRoute: '/',
                  observers: [_shellRouteObserver],
                  onGenerateRoute: _onGenerateRoute,
                ),
              ),
              const ObjectiveBar(),
              const SirenCountdown(),
              NotificationBanner(key: _bannerKey),
              const TopNoticeStrip(),
              GlitchOverlay(key: _glitchKey),
              const StoryOverlays(),
            ],
          ),
        ),
      ),
    );
  }
}
