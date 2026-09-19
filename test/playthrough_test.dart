import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/engine/game_state.dart';
import 'package:hollowmere_files/engine/save_store.dart';
import 'package:hollowmere_files/engine/script.dart';
import 'package:hollowmere_files/engine/script_repository.dart';
import 'package:hollowmere_files/engine/story_engine.dart';

/// Drives the real engine through all six episodes headlessly, under fake
/// time, with a scripted "player policy". This proves the JSON content and the
/// interpreter agree end to end and that each ending is actually reachable.
ScriptRepository _repo() => ScriptRepository({
      for (final id in ScriptRepository.episodeIds)
        id: EpisodeScript.fromJsonString(
            File('assets/story/$id.json').readAsStringSync()),
    });

typedef Policy = int Function(ChoiceInteraction it, List<int> visible, GameState g);

class Playthrough {
  Playthrough({required this.policy, required this.solvePuzzles, required this.accuse});

  final Policy policy;
  final bool solvePuzzles;
  final String accuse;

  final visited = <String>[];

  GameState run() {
    late GameState result;
    fakeAsync((async) {
      final container = ProviderContainer(overrides: [
        scriptRepositoryProvider.overrideWithValue(_repo()),
        saveStoreProvider.overrideWithValue(MemorySaveStore()),
      ]);
      final engine = container.read(storyEngineProvider.notifier);
      engine.newGame(playerName: 'Test');

      var steps = 0;
      while (steps++ < 4000) {
        async.elapse(const Duration(seconds: 6));
        final session = container.read(storyEngineProvider);
        final it = session.interaction;
        final node = session.game.nodeId;
        if (node != null) visited.add('${session.game.episodeId}/$node');

        switch (it) {
          case EndingInteraction():
            result = session.game;
            container.dispose();
            return;
          case ChoiceInteraction():
            final visible = engine.visibleOptions(it);
            expect(visible, isNotEmpty, reason: 'no visible options at $node');
            engine.choose(policy(it, visible, session.game));
          case GoalInteraction():
            engine.report(session.game.objective!.target);
          case MinigameInteraction():
            if (it.game == 'accuse') {
              engine.applyEffects({'flags': ['accused_$accuse', 'board_locked']});
              engine.completeMinigame();
            } else {
              engine.completeMinigame(skipped: !solvePuzzles);
            }
          case CallInteraction():
            // Calls apply their choice effects in the UI; emulate the first
            // option of each choice so branch-specific evidence is exercised.
            for (final item in it.script) {
              final choice = item['choice'] as List?;
              if (choice == null) continue;
              final first = (choice.first as Map<String, dynamic>)['effects'];
              if (first != null) engine.applyEffects(Map<String, dynamic>.from(first as Map));
            }
            engine.finishCall();
          case TitleInteraction():
          case SceneInteraction():
          case EpisodeEndInteraction():
            engine.dismissOverlay();
          case IdleInteraction():
          case TypingInteraction():
            // Still animating; elapse more time.
            engine.skip();
          case MenuInteraction():
            fail('Dropped to menu mid-game at $node');
        }
      }
      fail('Playthrough did not reach an ending in 4000 steps. Last: ${visited.last}');
    });
    return result;
  }
}

/// Prefers options that raise trust, share evidence and go to the police.
int _thoroughPolicy(ChoiceInteraction it, List<int> visible, GameState g) {
  int score(Map<String, dynamic> o) {
    final fx = (o['effects'] as Map<String, dynamic>?) ?? const {};
    var s = 0;
    final trust = (fx['trust'] as Map<String, dynamic>?) ?? const {};
    for (final v in trust.values) {
      s += (v as int) * 10;
    }
    final flags = ((fx['flags'] as List?) ?? const []).cast<String>();
    if (flags.contains('shared_evidence')) s += 50;
    if (flags.contains('fork_police')) s += 20;
    if (flags.contains('bait_north_dock')) s += 40;
    if (flags.any((f) => f.startsWith('warden_defied'))) s += 5;
    if (fx.containsKey('evidence')) s += 30;
    return s;
  }
  var best = visible.first;
  var bestScore = -1 << 30;
  for (final i in visible) {
    final sc = score(it.node.options[i]);
    if (sc > bestScore) {
      best = i;
      bestScore = sc;
    }
  }
  return best;
}

/// Always obeys the Warden, goes to the police, withholds evidence.
int _wardenPolicy(ChoiceInteraction it, List<int> visible, GameState g) {
  for (final i in visible) {
    final fx = (it.node.options[i]['effects'] as Map<String, dynamic>?) ?? const {};
    final flags = ((fx['flags'] as List?) ?? const []).cast<String>();
    if (flags.any((f) => f.startsWith('warden_obeyed'))) return i;
    if (flags.contains('fork_police') && !flags.contains('shared_evidence')) return i;
  }
  return visible.first;
}

/// Reckless: goes alone, alienates everyone.
int _recklessPolicy(ChoiceInteraction it, List<int> visible, GameState g) {
  int score(Map<String, dynamic> o) {
    final fx = (o['effects'] as Map<String, dynamic>?) ?? const {};
    var s = 0;
    final trust = (fx['trust'] as Map<String, dynamic>?) ?? const {};
    for (final v in trust.values) {
      s -= (v as int) * 10;
    }
    final flags = ((fx['flags'] as List?) ?? const []).cast<String>();
    if (flags.contains('fork_alone')) s += 50;
    return s;
  }
  var best = visible.first;
  var bestScore = -1 << 30;
  for (final i in visible) {
    final sc = score(it.node.options[i]);
    if (sc > bestScore) {
      best = i;
      bestScore = sc;
    }
  }
  return best;
}

void main() {
  test('thorough player who accuses Ardis reaches THE FILES', () {
    final p = Playthrough(policy: _thoroughPolicy, solvePuzzles: true, accuse: 'ardis');
    final g = p.run();
    expect(g.ending, 'files');
    expect(g.completedEpisodes, containsAll(ScriptRepository.episodeIds));
    expect(g.evidence.length, greaterThanOrEqualTo(15));
    expect(g.flags, contains('wren_alive_confirmed'));
    expect(g.flags, contains('message_read'));
    expect(g.flags, contains('bait_north_dock'));
    expect(g.evidence, contains('ev_second_viewer'));
    expect(g.evidence, contains('ev_bait_car'));
  });

  test('puzzle-skipper who still names Ardis gets HIGH WATER or worse', () {
    final p = Playthrough(policy: _thoroughPolicy, solvePuzzles: false, accuse: 'ardis');
    final g = p.run();
    expect(g.ending, anyOf('high_water', 'radio_silence'));
    expect(g.ending, isNot('files'));
  });

  test('accusing the wrong person is RADIO SILENCE', () {
    final p = Playthrough(policy: _thoroughPolicy, solvePuzzles: true, accuse: 'jonah');
    expect(p.run().ending, 'radio_silence');
  });

  test('obeying the Warden and withholding evidence is THE WARDEN', () {
    final p = Playthrough(policy: _wardenPolicy, solvePuzzles: true, accuse: 'ardis');
    final g = p.run();
    expect(g.flags, contains('warden_obeyed_all'));
    expect(g.ending, 'warden');
  });

  test('going alone with no ally is RADIO SILENCE even with the right name', () {
    final p = Playthrough(policy: _recklessPolicy, solvePuzzles: true, accuse: 'ardis');
    final g = p.run();
    expect(g.flags, contains('fork_alone'));
    expect(g.ending, 'radio_silence');
  });

  test('a save mid-episode resumes at the same node', () {
    fakeAsync((async) {
      final store = MemorySaveStore();
      final container = ProviderContainer(overrides: [
        scriptRepositoryProvider.overrideWithValue(_repo()),
        saveStoreProvider.overrideWithValue(store),
      ]);
      final engine = container.read(storyEngineProvider.notifier);
      engine.newGame();
      async.elapse(const Duration(seconds: 10));
      // Advance past the cold-open goal and into the first choice.
      var guard = 0;
      while (container.read(storyEngineProvider).interaction is! ChoiceInteraction) {
        expect(++guard, lessThan(80), reason: 'never reached first choice');
        final session = container.read(storyEngineProvider);
        final it = session.interaction;
        if (it is TitleInteraction || it is SceneInteraction) {
          engine.dismissOverlay();
        } else if (it is GoalInteraction) {
          engine.report(session.game.objective!.target);
        } else if (it is MinigameInteraction) {
          engine.completeMinigame();
        } else {
          engine.skip();
        }
        async.elapse(const Duration(seconds: 3));
      }
      async.elapse(const Duration(seconds: 1)); // let the save debounce fire
      final saved = store.load();
      expect(saved, isNotNull);
      expect(saved!.nodeId, container.read(storyEngineProvider).game.nodeId);
      expect(saved.threads['wren'], isNotEmpty);
      container.dispose();
    });
  });
}
