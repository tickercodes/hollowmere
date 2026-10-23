import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/content/browser_pages.dart';
import 'package:hollowmere_files/content/characters.dart';
import 'package:hollowmere_files/content/endings.dart';
import 'package:hollowmere_files/content/evidence.dart';
import 'package:hollowmere_files/content/photos.dart';
import 'package:hollowmere_files/content/voicemails.dart';
import 'package:hollowmere_files/content/voices.dart';
import 'package:hollowmere_files/engine/game_state.dart';
import 'package:hollowmere_files/engine/reducer.dart';
import 'package:hollowmere_files/engine/script.dart';
import 'package:hollowmere_files/engine/script_repository.dart';
import 'package:hollowmere_files/features/shell/app_registry.dart';
import 'package:hollowmere_files/minigames/logic/sudoku.dart';
import 'package:hollowmere_files/minigames/minigame_config.dart';
import 'package:hollowmere_files/minigames/minigame_router.dart';

/// Loads every episode straight from disk (no Flutter binding needed).
Map<String, EpisodeScript> loadEpisodes() => {
      for (final id in ScriptRepository.episodeIds)
        id: EpisodeScript.fromJsonString(
            File('assets/story/$id.json').readAsStringSync()),
    };

void main() {
  final episodes = loadEpisodes();
  final appIds = phoneApps.map((a) => a.id).toSet();

  test('all six episodes exist, are numbered, and validate', () {
    expect(episodes.length, 6);
    for (final ep in episodes.values) {
      expect(ep.validate(), isEmpty, reason: ep.id);
      expect(ep.number, int.parse(ep.id.substring(2)));
    }
  });

  test('episodes chain ep1 -> ep6 and the last one ends the game', () {
    for (var i = 1; i <= 6; i++) {
      final ep = episodes['ep$i']!;
      final ends = ep.nodes.values.where((n) => n.type == 'end_episode').toList();
      final endings = ep.nodes.values.where((n) => n.type == 'ending').toList();
      if (i < 6) {
        expect(ends, isNotEmpty, reason: '$i must end_episode');
        for (final e in ends) {
          expect(e['next_episode'], 'ep${i + 1}');
        }
      } else {
        expect(endings, isNotEmpty, reason: 'ep6 must reach an ending');
      }
    }
  });

  test('every node reference resolves to real content', () {
    for (final ep in episodes.values) {
      for (final n in ep.nodes.values) {
        final where = '${ep.id}/${n.id}';
        void checkEffects(Map<String, dynamic>? e) {
          if (e == null) return;
          // Applying to a blank state throws on unknown keys/shapes.
          final s = Reducer.applyEffects(GameState(), e);
          for (final ev in s.evidence) {
            expect(evidenceCatalog.containsKey(ev), isTrue, reason: '$where evidence $ev');
          }
          for (final app in s.unlockedApps) {
            expect(appIds.contains(app), isTrue, reason: '$where app $app');
          }
          for (final g in s.gallery) {
            expect(photos.containsKey(g.photo), isTrue, reason: '$where photo ${g.photo}');
          }
          for (final c in s.callLog) {
            expect(characters.containsKey(c.contact), isTrue, reason: '$where contact ${c.contact}');
            if (c.voicemail != null) {
              expect(voicemails.containsKey(c.voicemail), isTrue, reason: '$where vm ${c.voicemail}');
            }
          }
          for (final p in s.pages) {
            expect(webPages.containsKey(p), isTrue, reason: '$where page $p');
          }
          for (final pin in s.boardPins) {
            expect(boardPins.containsKey(pin), isTrue, reason: '$where pin $pin');
          }
          for (final f in s.feed) {
            if (f.image != null) {
              expect(photos.containsKey(f.image), isTrue, reason: '$where feed image ${f.image}');
            }
          }
        }

        checkEffects(n.raw['effects'] as Map<String, dynamic>?);
        for (final o in n.options) {
          checkEffects(o['effects'] as Map<String, dynamic>?);
        }
        if (n['voice'] != null) {
          expect(spokenVoiceIds.contains(n['voice']), isTrue,
              reason: '$where voice ${n['voice']}');
        }

        switch (n.type) {
          case 'message':
            expect(characters.containsKey(n['thread']), isTrue, reason: '$where thread');
            final from = n['from'] as String?;
            if (from != null) expect(characters.containsKey(from), isTrue, reason: '$where from');
            if (n['image'] != null) {
              expect(() => photoOf(n['image'] as String), returnsNormally, reason: '$where image');
            }
          case 'choice':
            expect(characters.containsKey(n['thread']), isTrue, reason: '$where thread');
          case 'glitch':
            final ghost = n['ghost'] as Map<String, dynamic>?;
            if (ghost?['thread'] != null) {
              expect(characters.containsKey(ghost!['thread']), isTrue, reason: where);
            }
          case 'scene':
            expect(n['lines'], isA<List>(), reason: where);
            if (n['image'] != null) {
              expect(() => photoOf(n['image'] as String), returnsNormally, reason: '$where scene image');
            }
          case 'notification':
            expect(appIds.contains(n['app']), isTrue, reason: '$where app ${n['app']}');
          case 'goal':
            final target = Map<String, String>.from(n['target'] as Map);
            expect(appIds.contains(target['app']), isTrue, reason: '$where goal app');
            if (target['photo'] != null) {
              expect(() => photoOf(target['photo']!), returnsNormally, reason: '$where goal photo');
            }
            if (target['thread'] != null) {
              expect(characters.containsKey(target['thread']), isTrue, reason: '$where goal thread');
            }
            if (target['voicemail'] != null) {
              expect(voicemails.containsKey(target['voicemail']), isTrue, reason: '$where goal vm');
            }
            if (target['page'] != null) {
              expect(webPages.containsKey(target['page']), isTrue, reason: '$where goal page');
            }
          case 'call':
            expect(characters.containsKey(n['contact']), isTrue, reason: '$where contact');
            for (final item in (n['script'] as List).cast<Map<String, dynamic>>()) {
              if (item.containsKey('choice')) {
                for (final o in (item['choice'] as List).cast<Map<String, dynamic>>()) {
                  checkEffects(o['effects'] as Map<String, dynamic>?);
                }
              } else if (item['end'] != true) {
                expect(item['text'], isA<String>(), reason: '$where call line');
                expect(characters.containsKey(item['from']), isTrue, reason: '$where call from');
              }
            }
          case 'minigame':
            expect(minigameIds.contains(n['game']), isTrue, reason: '$where game ${n['game']}');
            if (n['evidence'] != null) {
              expect(evidenceCatalog.containsKey(n['evidence']), isTrue, reason: '$where evidence');
            }
            expect(n.hints.length, inInclusiveRange(0, 3), reason: '$where hints');
            _checkMinigameConfig(n, where);
          case 'ending':
            if (n['id'] != null) expect(endings.containsKey(n['id']), isTrue, reason: where);
        }
      }
    }
  });

  test('every spoken voice is attached to at least one story beat', () {
    final used = <String>{};
    for (final ep in episodes.values) {
      for (final n in ep.nodes.values) {
        final v = n['voice'] as String?;
        if (v != null) used.add(v);
      }
    }
    expect(used, spokenVoiceIds);
  });

  test('every node is reachable from start', () {
    for (final ep in episodes.values) {
      final seen = <String>{};
      final stack = [ep.start];
      while (stack.isNotEmpty) {
        final id = stack.removeLast();
        if (!seen.add(id)) continue;
        final n = ep.nodes[id]!;
        void push(String? t) {
          if (t != null) stack.add(t);
        }
        push(n.next);
        for (final o in n.options) {
          push(o['next'] as String?);
        }
        push(n['then'] as String?);
        push(n['else'] as String?);
      }
      final unreachable = ep.nodes.keys.toSet().difference(seen);
      expect(unreachable, isEmpty, reason: '${ep.id} unreachable: $unreachable');
    }
  });

  test('sudoku shaded cells spell the codes the story relies on', () {
    for (final ep in episodes.values) {
      for (final n in ep.nodes.values) {
        if (n.type != 'minigame' || n['game'] != 'sudoku') continue;
        final cfg = n.config;
        final s = Sudoku.generate(
          seed: cfg['seed'] as int,
          size: (cfg['size'] as int?) ?? 9,
          givens: (cfg['givens'] as int?) ?? 62,
        );
        final cells = (cfg['shaded'] as List).map((e) => (e as List).cast<int>()).toList();
        expect(s.codeAt(cells), cfg['expected_code'], reason: '${ep.id}/${n.id}');
      }
    }
  });

  test('ep1 cold open reaches the first mini-game within a few dozen nodes', () {
    // Retention guard: the first "aha" must be near the start of the graph.
    final ep = episodes['ep1']!;
    var id = ep.start;
    var steps = 0;
    while (steps < 60) {
      final n = ep.node(id);
      if (n.type == 'minigame') break;
      id = n.next ?? (n.options.isNotEmpty ? n.options.first['next'] as String : '');
      if (id.isEmpty) fail('dead end before first minigame at ${n.id}');
      steps++;
    }
    expect(steps, lessThan(60));
  });

  test('flags the ending resolver reads are actually set somewhere', () {
    final all = jsonEncode(episodes.values.map((e) => e.nodes.values.map((n) => n.raw).toList()).toList());
    for (final flag in ['accused_ardis', 'fork_alone', 'fork_police', 'warden_obeyed_all', 'shared_evidence', 'bait_north_dock']) {
      final setByAccuseGame = flag == 'accused_ardis';
      if (!setByAccuseGame) {
        expect(all.contains('"$flag"'), isTrue, reason: 'flag $flag never set');
      }
    }
  });
}

void _checkMinigameConfig(StoryNode n, String where) {
  final c = n.config;
  switch (n['game']) {
    case 'passcode':
      expect(c['answer'], isA<String>(), reason: where);
    case 'photo_spot':
      final photoId = MinigameConfig.photoId(c);
      expect(() => photoOf(photoId), returnsNormally, reason: where);
      final ids = photoOf(photoId).hotspots.map((h) => h.id).toSet();
      for (final r in (c['required'] as List?) ?? const []) {
        expect(ids.contains(r), isTrue, reason: '$where hotspot $r');
      }
    case 'order':
      final items = MinigameConfig.orderItems(c).map((i) => i['id']).toSet();
      expect(MinigameConfig.orderAnswer(c).toSet(), items, reason: where);
    case 'key_cipher':
      expect(c['ciphertext'], isA<String>(), reason: where);
      expect(c['key'], isA<List>(), reason: where);
      final markIds = (c['marks'] as List)
          .cast<Map<String, dynamic>>()
          .map((m) => m['id'])
          .toSet();
      expect((c['key'] as List).every(markIds.contains), isTrue, reason: where);
    case 'cipher':
      expect(c['answer'], isA<String>(), reason: where);
      if (c['type'] == 'shift' || c['ciphertext'] != null) {
        expect(c['ciphertext'], isA<String>(), reason: where);
        expect(c['shift'], isA<int>(), reason: where);
      } else {
        expect(c['cipher'], isA<String>(), reason: where);
        expect(c['legend'], isA<Map>(), reason: where);
      }
    case 'sudoku':
      expect(c['seed'] != null || c['grid'] != null, isTrue, reason: where);
    case 'audio_tag':
      expect(voicemails.containsKey(c['voicemail']), isTrue, reason: where);
      final cues = voicemailOf(c['voicemail'] as String).cues.map((x) => x.id).toSet();
      for (final r in (c['required'] as List?) ?? const []) {
        expect(cues.contains(r), isTrue, reason: '$where cue $r');
      }
    case 'feed_scrub':
      expect(c['target'] != null || c['target_time'] != null, isTrue, reason: where);
    case 'board_connect':
      for (final pair in MinigameConfig.boardRequired(c)) {
        for (final p in pair) {
          expect(boardPins.containsKey(p), isTrue, reason: '$where pin $p');
        }
      }
    case 'live_static':
      expect(
        MinigameConfig.liveSteps(c).isNotEmpty || MinigameConfig.tuneFrequency(c) != null,
        isTrue,
        reason: where,
      );
    case 'log_diff':
      expect(MinigameConfig.logRows(c), isNotEmpty, reason: where);
    case 'voice_match':
      for (final clip in MinigameConfig.voiceClips(c)) {
        expect(voicemails.containsKey(clip['voicemail']), isTrue, reason: where);
        expect(MinigameConfig.voiceOptions(c).contains(clip['answer']), isTrue, reason: where);
      }
    case 'accuse':
      for (final s in (c['suspects'] as List)) {
        expect(boardPins.containsKey(s), isTrue, reason: '$where suspect $s');
      }
  }
}
