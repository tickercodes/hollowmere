/// The asynchronous interpreter that walks an [EpisodeScript], applying pure
/// [Reducer] transitions and pausing at points that need the player.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_state.dart';
import 'reducer.dart';
import 'save_store.dart';
import 'script.dart';
import 'script_repository.dart';

/// What the UI must render on top of the phone right now.
sealed class Interaction {
  const Interaction();
}

class MenuInteraction extends Interaction {
  const MenuInteraction();
}

class IdleInteraction extends Interaction {
  const IdleInteraction();
}

class TypingInteraction extends Interaction {
  const TypingInteraction(this.thread, this.from);
  final String thread;
  final String from;
}

class ChoiceInteraction extends Interaction {
  const ChoiceInteraction(this.node);
  final StoryNode node;
  String get thread => node['thread'] as String;
}

class GoalInteraction extends Interaction {
  const GoalInteraction();
}

class MinigameInteraction extends Interaction {
  const MinigameInteraction(this.node);
  final StoryNode node;
  String get game => node['game'] as String;
  String get puzzleId => node.id;
}

class CallInteraction extends Interaction {
  const CallInteraction(this.node);
  final StoryNode node;
  String get contact => node['contact'] as String;
  bool get incoming => node['incoming'] != false;
  List<Map<String, dynamic>> get script =>
      (node['script'] as List).cast<Map<String, dynamic>>();
}

class TitleInteraction extends Interaction {
  const TitleInteraction(this.node);
  final StoryNode node;
}

class SceneInteraction extends Interaction {
  const SceneInteraction(this.node);
  final StoryNode node;
}

class EpisodeEndInteraction extends Interaction {
  const EpisodeEndInteraction(this.node, this.episode);
  final StoryNode node;
  final EpisodeScript episode;
}

class EndingInteraction extends Interaction {
  const EndingInteraction(this.endingId);
  final String endingId;
}

class AppNotification {
  const AppNotification({required this.app, required this.title, required this.body});
  final String app;
  final String title;
  final String body;
}

class GlitchEvent {
  const GlitchEvent({this.ghostText, this.ghostFrom});
  final String? ghostText;
  final String? ghostFrom;
}

class Session {
  const Session(this.game, this.interaction);
  final GameState game;
  final Interaction interaction;
  Session copyWith({GameState? game, Interaction? interaction}) =>
      Session(game ?? this.game, interaction ?? this.interaction);
}

final scriptRepositoryProvider =
    Provider<ScriptRepository>((_) => throw UnimplementedError('override'));
final saveStoreProvider =
    Provider<SaveStore>((_) => throw UnimplementedError('override'));

final storyEngineProvider =
    NotifierProvider<StoryEngine, Session>(StoryEngine.new);

class StoryEngine extends Notifier<Session> {
  final _notifications = StreamController<AppNotification>.broadcast();
  final _sfx = StreamController<String>.broadcast();
  final _whispers = StreamController<String>.broadcast();
  final _glitches = StreamController<GlitchEvent>.broadcast();

  Stream<AppNotification> get notifications => _notifications.stream;
  Stream<String> get sfx => _sfx.stream;
  /// Scripted story line ids (`voice_*`). Empty unless the current node asked.
  Stream<String> get whispers => _whispers.stream;
  Stream<GlitchEvent> get glitches => _glitches.stream;

  Completer<void>? _skip;
  bool _running = false;
  int _messageCounter = 0;
  Timer? _saveDebounce;

  ScriptRepository get _scripts => ref.read(scriptRepositoryProvider);
  SaveStore get _store => ref.read(saveStoreProvider);

  @override
  Session build() {
    ref.onDispose(() {
      _notifications.close();
      _sfx.close();
      _whispers.close();
      _glitches.close();
      _saveDebounce?.cancel();
    });
    final saved = _store.load();
    if (saved != null && saved.nodeId != null) {
      // Resume: re-enter the current node so blocking interactions rebuild.
      scheduleMicrotask(_run);
      return Session(saved, const IdleInteraction());
    }
    return Session(saved ?? GameState(), const MenuInteraction());
  }

  GameState get game => state.game;
  EpisodeScript get episode => _scripts.episode(game.episodeId);

  // ------------------------------------------------------------ public API

  Future<void> newGame({String playerName = 'John'}) async {
    _setGame(GameState(playerName: playerName));
    await startEpisode('ep1');
  }

  Future<void> startEpisode(String id) async {
    final ep = _scripts.episode(id);
    _setGame(game.copyWith(
      episodeId: id,
      nodeId: ep.start,
      clearObjective: true,
      ghostsSavedThisEpisode: 0,
    ));
    await _run();
  }

  /// Player tapped the screen while text was appearing: finish the wait now.
  void skip() {
    final c = _skip;
    if (c != null && !c.isCompleted) c.complete();
  }

  void choose(int index) {
    final it = state.interaction;
    if (it is! ChoiceInteraction) return;
    final option = it.node.options[index];
    var g = game;
    final say = option['say'] as String? ?? option['text'] as String;
    if (option['silent'] != true && say.isNotEmpty) {
      g = Reducer.appendMessage(g, it.thread, _msg('player', _fill(say)));
      _sfx.add('message_out');
    }
    g = Reducer.applyEffects(g, (option['effects'] as Map<String, dynamic>?) ?? {});
    g = g.copyWith(nodeId: option['next'] as String);
    _setGame(g, interaction: const IdleInteraction());
    _run();
  }

  /// Options currently visible for a choice (respecting `if` conditions).
  List<int> visibleOptions(ChoiceInteraction it) {
    final ctx = StateConditions(game);
    return [
      for (var i = 0; i < it.node.options.length; i++)
        if (Condition.evaluate(
            it.node.options[i]['if'] as Map<String, dynamic>?, ctx))
          i
    ];
  }

  /// The UI reports player actions (opening apps, viewing photos, threads).
  void report(Map<String, String> action) {
    final obj = game.objective;
    if (obj == null || state.interaction is! GoalInteraction) return;
    final matches = obj.target.entries.every((e) => action[e.key] == e.value);
    if (!matches) return;
    final node = episode.node(game.nodeId!);
    _setGame(
      Reducer.applyEffects(game, node.effects)
          .copyWith(nodeId: node.next, clearObjective: true),
      interaction: const IdleInteraction(),
    );
    _run();
  }

  void openThread(String thread) => _setGame(Reducer.markThreadRead(game, thread));

  /// Hold a vanishing mirror message. Returns false if the cap is hit.
  bool saveVanishing(String thread, String messageId) {
    final before = game.ghostsSavedThisEpisode;
    final next = Reducer.saveVanishing(game, thread, messageId);
    if (next.ghostsSavedThisEpisode == before) return false;
    _sfx.add('unlock');
    _setGame(next);
    return true;
  }

  /// Called by mini-game screens. `skipped` grants progress without evidence.
  void completeMinigame({bool skipped = false}) {
    final it = state.interaction;
    if (it is! MinigameInteraction) return;
    var g = game;
    if (skipped) {
      g = Reducer.applyEffects(g, {
        'flags': ['skipped_${it.puzzleId}'],
        'journal': 'Skipped a puzzle: ${it.node['title'] ?? it.game}.',
      });
    } else {
      _sfx.add('unlock');
      g = Reducer.applyEffects(g, it.node.effects);
      final ev = it.node['evidence'] as String?;
      if (ev != null) g = Reducer.applyEffects(g, {'evidence': [ev]});
    }
    _setGame(g.copyWith(nodeId: it.node.next), interaction: const IdleInteraction());
    _run();
  }

  void failMinigame(String puzzleId) {
    _sfx.add('error');
    _setGame(Reducer.addFail(game, puzzleId));
  }

  void useHint(String puzzleId) => _setGame(Reducer.addHint(game, puzzleId));

  void applyEffects(Map<String, dynamic> effects) =>
      _setGame(Reducer.applyEffects(game, effects));

  void finishCall() {
    final it = state.interaction;
    if (it is! CallInteraction) return;
    _setGame(
      Reducer.applyEffects(game, it.node.effects).copyWith(nodeId: it.node.next),
      interaction: const IdleInteraction(),
    );
    _run();
  }

  /// Dismisses title cards, scenes and episode-end cards.
  void dismissOverlay() {
    switch (state.interaction) {
      case TitleInteraction(:final node):
        _advance(node);
      case SceneInteraction(:final node):
        _advance(node);
      case EpisodeEndInteraction(:final node):
        final next = node['next_episode'] as String?;
        if (next != null) {
          startEpisode(next);
        } else {
          _setGame(game.copyWith(clearNode: true),
              interaction: const MenuInteraction());
        }
      default:
        return;
    }
  }

  void toggleLink(String a, String b) => _setGame(Reducer.toggleLink(game, a, b));

  void setTextSpeed(double v) => _setGame(game.copyWith(textSpeed: v));

  Future<void> resetProgress() async {
    _running = false;
    skip();
    await _store.clear();
    state = Session(GameState(), const MenuInteraction());
  }

  void backToMenu() => state = state.copyWith(interaction: const MenuInteraction());

  /// Resume from menu when a save exists.
  void resume() {
    if (game.nodeId == null) return;
    _run();
  }

  // ---------------------------------------------------------------- loop

  void _advance(StoryNode node) {
    _setGame(
      Reducer.applyEffects(game, node.effects).copyWith(nodeId: node.next),
      interaction: const IdleInteraction(),
    );
    _run();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    try {
      while (_running) {
        final nodeId = game.nodeId;
        if (nodeId == null) break;
        final node = episode.node(nodeId);
        final blocked = await _execute(node);
        if (blocked) break;
      }
    } finally {
      _running = false;
    }
  }

  /// Executes one node. Returns true when the loop must wait for the player.
  Future<bool> _execute(StoryNode node) async {
    final voice = node['voice'] as String?;
    if (voice != null && voice.isNotEmpty) _whispers.add(voice);
    switch (node.type) {
      case 'message':
        final thread = node['thread'] as String;
        final from = node['from'] as String? ?? thread;
        final text = node['text'] as String;
        if (from != 'player') {
          state = state.copyWith(interaction: TypingInteraction(thread, from));
          await _wait(_typingSeconds(node, text));
          _sfx.add('message_in');
        }
        _setGame(
          Reducer.appendMessage(
              game, thread, _msg(from, _fill(text), image: node['image'] as String?)),
          interaction: const IdleInteraction(),
        );
        _next(node);
        // A brief beat between consecutive incoming messages reads better.
        if (from != 'player') await _wait(0.25);
        return false;

      case 'choice':
        state = state.copyWith(interaction: ChoiceInteraction(node));
        return true;

      case 'notification':
        _notifications.add(AppNotification(
          app: node['app'] as String,
          title: _fill(node['title'] as String),
          body: _fill(node['body'] as String),
        ));
        _sfx.add('notification');
        await _wait((node['delay'] as num?)?.toDouble() ?? 1.4);
        _next(node);
        return false;

      case 'goal':
        _setGame(
          game.copyWith(
            objective: Objective(
              text: _fill(node['text'] as String),
              target: Map<String, String>.from(node['target'] as Map),
            ),
          ),
          interaction: const GoalInteraction(),
        );
        return true;

      case 'minigame':
        state = state.copyWith(interaction: MinigameInteraction(node));
        return true;

      case 'call':
        _sfx.add(node['incoming'] == false ? 'tap' : 'ringtone');
        state = state.copyWith(interaction: CallInteraction(node));
        return true;

      case 'title':
        state = state.copyWith(interaction: TitleInteraction(node));
        return true;

      case 'scene':
        state = state.copyWith(interaction: SceneInteraction(node));
        return true;

      case 'glitch':
        final ghost = node['ghost'] as Map<String, dynamic>?;
        _sfx.add('glitch');
        _glitches.add(GlitchEvent(
          ghostText: ghost?['text'] as String?,
          ghostFrom: ghost?['from'] as String?,
        ));
        if (ghost != null && ghost['thread'] != null) {
          final m = _msg(
            ghost['from'] as String,
            _fill(ghost['text'] as String),
            vanishing: true,
          );
          _setGame(Reducer.appendMessage(game, ghost['thread'] as String, m,
              markUnread: false));
          await _wait(2.8);
          _setGame(Reducer.strikeMessage(game, ghost['thread'] as String, m.id));
        } else {
          await _wait(1.6);
        }
        _next(node);
        return false;

      case 'effects':
        _next(node);
        return false;

      case 'delay':
        await _wait((node['seconds'] as num).toDouble());
        _next(node);
        return false;

      case 'branch':
        final ok = Condition.evaluate(
            node['if'] as Map<String, dynamic>?, StateConditions(game));
        _setGame(game.copyWith(nodeId: (ok ? node['then'] : node['else']) as String));
        return false;

      case 'end_episode':
        _setGame(
          Reducer.applyEffects(game, node.effects).copyWith(
            completedEpisodes: Set.from(game.completedEpisodes)..add(episode.id),
            clearObjective: true,
          ),
          interaction: EpisodeEndInteraction(node, episode),
        );
        return true;

      case 'ending':
        final id = (node['id'] as String?) ?? Reducer.resolveEnding(game);
        _setGame(
          Reducer.applyEffects(game, node.effects).copyWith(
            ending: id,
            completedEpisodes: Set.from(game.completedEpisodes)..add(episode.id),
            clearNode: true,
            clearObjective: true,
          ),
          interaction: EndingInteraction(id),
        );
        return true;

      default:
        throw StateError('Unhandled node type ${node.type}');
    }
  }

  void _next(StoryNode node) {
    _setGame(Reducer.applyEffects(game, node.effects).copyWith(nodeId: node.next));
  }

  /// Typing indicator time: capped so chats never drag (bible §12).
  double _typingSeconds(StoryNode node, String text) {
    final explicit = (node['delay'] as num?)?.toDouble();
    final base = explicit ?? (0.25 + 0.35 * math.min(1.0, text.length / 100));
    return base * game.textSpeed;
  }

  Future<void> _wait(double seconds) async {
    if (seconds <= 0) return;
    final c = Completer<void>();
    _skip = c;
    final t = Timer(Duration(milliseconds: (seconds * 1000).round()), () {
      if (!c.isCompleted) c.complete();
    });
    await c.future;
    t.cancel();
    if (identical(_skip, c)) _skip = null;
  }

  ChatMessage _msg(String from, String text, {String? image, bool vanishing = false}) =>
      ChatMessage(
        id: 'm${DateTime.now().microsecondsSinceEpoch}_${_messageCounter++}',
        from: from,
        text: text,
        image: image,
        vanishing: vanishing,
      );

  /// Substitutes `{player}` with the chosen name.
  String _fill(String text) => text.replaceAll('{player}', game.playerName);

  void _setGame(GameState g, {Interaction? interaction}) {
    state = Session(g, interaction ?? state.interaction);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () => _store.save(g));
  }
}
