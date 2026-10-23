import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/content/evidence.dart';
import 'package:hollowmere_files/engine/game_state.dart';
import 'package:hollowmere_files/engine/reducer.dart';
import 'package:hollowmere_files/engine/script.dart';
import 'package:hollowmere_files/minigames/logic/cipher.dart';
import 'package:hollowmere_files/minigames/logic/sudoku.dart';

GameState _withEvidence(int n, {Set<String> flags = const {}, Map<String, int> trust = const {}}) {
  final ids = evidenceCatalog.keys.take(n).toSet();
  return GameState(evidence: ids, flags: flags, trust: trust);
}

void main() {
  group('Reducer.applyEffects', () {
    test('adds flags, trust, evidence and unlocks apps', () {
      final s = Reducer.applyEffects(GameState(), {
        'flags': ['a'],
        'trust': {'jonah': 2},
        'evidence': ['ev_unread'],
        'unlock_apps': ['calls'],
      });
      expect(s.has('a'), isTrue);
      expect(s.trustOf('jonah'), 2);
      expect(s.evidence, {'ev_unread'});
      expect(s.unlockedApps, containsAll({'messages', 'calls'}));
    });

    test('trust accumulates and unflag removes', () {
      var s = Reducer.applyEffects(GameState(), {'trust': {'mara': 1}, 'flags': ['x']});
      s = Reducer.applyEffects(s, {'trust': {'mara': -3}, 'unflag': ['x']});
      expect(s.trustOf('mara'), -2);
      expect(s.has('x'), isFalse);
    });

    test('unknown effect keys throw so typos surface in tests', () {
      expect(() => Reducer.applyEffects(GameState(), {'flagz': []}), throwsArgumentError);
    });

    test('gallery replaces an item with the same photo id', () {
      var s = Reducer.applyEffects(GameState(), {
        'gallery': [{'photo': 'dock_night', 'locked': true}],
      });
      s = Reducer.applyEffects(s, {'unlock_photos': ['dock_night']});
      expect(s.gallery.single.locked, isFalse);
    });

    test('ghost messages are struck through, not removed', () {
      var s = Reducer.appendMessage(
          GameState(), 'wren', const ChatMessage(id: 'g1', from: 'wren', text: 'hi'),
          markUnread: false);
      s = Reducer.strikeMessage(s, 'wren', 'g1');
      expect(s.threads['wren']!.single.deleted, isTrue);
      expect(s.unreadThreads, isEmpty);
    });

    test('hold-to-save keeps a vanishing message and respects the cap', () {
      var s = GameState();
      for (var i = 0; i < GameState.ghostSaveCap + 1; i++) {
        s = Reducer.appendMessage(
          s,
          'wren',
          ChatMessage(id: 'g$i', from: 'wren', text: 'x$i', vanishing: true),
          markUnread: false,
        );
        s = Reducer.saveVanishing(s, 'wren', 'g$i');
      }
      expect(s.ghostsSavedThisEpisode, GameState.ghostSaveCap);
      expect(s.threads['wren']![0].saved, isTrue);
      expect(s.threads['wren']![0].vanishing, isFalse);
      expect(s.threads['wren']!.last.saved, isFalse);
      s = Reducer.strikeMessage(s, 'wren', 'g0');
      expect(s.threads['wren']![0].deleted, isFalse);
    });

    test('hours and siren countdown are first-class effects', () {
      var s = Reducer.applyEffects(GameState(), {'hours': 304});
      expect(s.hoursSinceRead, 304);
      s = Reducer.applyEffects(s, {'siren_seconds': 10});
      expect(s.sirenEndsAtMs, isNotNull);
      expect(s.sirenEndsAtMs! - DateTime.now().millisecondsSinceEpoch, closeTo(10000, 250));
    });
  });

  group('GameState serialisation', () {
    test('round-trips through JSON', () {
      final s = Reducer.applyEffects(GameState(playerName: 'Ada'), {
        'flags': ['f'],
        'trust': {'deacon': 2},
        'evidence': ['ev_unread'],
        'call_log': [{'id': 'c', 'contact': 'mara', 'direction': 'missed', 'label': 'x'}],
        'notes': [{'id': 'n', 'title': 't', 'body': 'b'}],
        'feed': [{'id': 'p', 'author': 'wren', 'text': 't', 'time': 'now'}],
        'pins': ['wren'],
        'mirror': 2,
      }).copyWith(nodeId: 'n1', episodeId: 'ep2');
      final back = GameState.fromJson(s.toJson());
      expect(back.playerName, 'Ada');
      expect(back.nodeId, 'n1');
      expect(back.episodeId, 'ep2');
      expect(back.flags, s.flags);
      expect(back.trustOf('deacon'), 2);
      expect(back.callLog.single.contact, 'mara');
      expect(back.notes.single.body, 'b');
      expect(back.feed.single.author, 'wren');
      expect(back.boardPins, {'wren'});
      expect(back.mirrorLevel, 2);
      expect(back.hoursSinceRead, 264);
    });
  });

  group('Reducer.resolveEnding', () {
    test('accusing anyone but Ardis is radio silence', () {
      expect(Reducer.resolveEnding(_withEvidence(19, flags: {'accused_jonah'})), 'radio_silence');
    });

    test('best ending needs Ardis, high evidence and backing when alone', () {
      expect(
        Reducer.resolveEnding(_withEvidence(Reducer.bestEndingEvidence,
            flags: {'accused_ardis', 'fork_police'})),
        'files',
      );
      expect(
        Reducer.resolveEnding(_withEvidence(19,
            flags: {'accused_ardis', 'fork_alone'}, trust: {'deacon': 2})),
        'files',
      );
    });

    test('alone with no ally is tragic regardless of evidence', () {
      expect(
        Reducer.resolveEnding(_withEvidence(19, flags: {'accused_ardis', 'fork_alone'})),
        'radio_silence',
      );
    });

    test('mid evidence is bittersweet', () {
      expect(
        Reducer.resolveEnding(_withEvidence(Reducer.minimumEvidence,
            flags: {'accused_ardis', 'fork_police'})),
        'high_water',
      );
    });

    test('too little evidence is tragic even with the right name', () {
      expect(
        Reducer.resolveEnding(_withEvidence(Reducer.minimumEvidence - 1,
            flags: {'accused_ardis', 'fork_police'})),
        'radio_silence',
      );
    });

    test('obeying the Warden and withholding evidence is the complicit ending', () {
      expect(
        Reducer.resolveEnding(_withEvidence(19,
            flags: {'accused_ardis', 'fork_police', 'warden_obeyed_all'})),
        'warden',
      );
      expect(
        Reducer.resolveEnding(_withEvidence(19,
            flags: {'accused_ardis', 'fork_police', 'warden_obeyed_all', 'shared_evidence'})),
        'files',
      );
    });
  });

  group('Condition', () {
    test('evaluates flags, trust bounds, evidence and combinators', () {
      final ctx = StateConditions(GameState(
        flags: {'a'},
        trust: {'jonah': 2},
        evidence: {'ev_unread', 'ev_notebook'},
      ));
      expect(Condition.evaluate({'flag': 'a'}, ctx), isTrue);
      expect(Condition.evaluate({'not_flag': 'a'}, ctx), isFalse);
      expect(Condition.evaluate({'trust': {'who': 'jonah', 'min': 2}}, ctx), isTrue);
      expect(Condition.evaluate({'trust': {'who': 'jonah', 'max': 1}}, ctx), isFalse);
      expect(Condition.evaluate({'evidence_min': 2}, ctx), isTrue);
      expect(Condition.evaluate({'has_evidence': 'ev_report'}, ctx), isFalse);
      expect(Condition.evaluate({'all': [{'flag': 'a'}, {'evidence_min': 3}]}, ctx), isFalse);
      expect(Condition.evaluate({'any': [{'flag': 'zz'}, {'evidence_min': 1}]}, ctx), isTrue);
      expect(Condition.evaluate(null, ctx), isTrue);
    });
  });

  group('Sudoku', () {
    test('is deterministic per seed with a unique solution', () {
      final a = Sudoku.generate(seed: 14, givens: 44);
      final b = Sudoku.generate(seed: 14, givens: 44);
      expect(a.puzzle, b.puzzle);
      expect(Sudoku.countSolutions(a.puzzle, 9), 1);
      expect(a.isSolved(a.solution), isTrue);
      expect(a.conflicts(a.solution), isEmpty);
    });

    test('flags conflicting entries', () {
      final s = Sudoku.generate(seed: 3, givens: 44);
      final grid = List<int>.from(s.solution);
      // Duplicate the first cell's value into the second cell of the same row.
      grid[1] = grid[0];
      expect(s.conflicts(grid), containsAll({0, 1}));
    });

    test('6x6 variant respects 2x3 boxes', () {
      final s = Sudoku.generate(seed: 7, size: 6, givens: 18);
      expect(s.solution.length, 36);
      expect(Sudoku.countSolutions(s.puzzle, 6), 1);
    });
  });

  group('Cipher', () {
    test('encode/decode with emoji symbols round-trips', () {
      const legend = {'L': '🌊', 'O': '🔑', 'C': '🍒', 'K': '🗝', 'E': '🌙', 'R': '🌧'};
      final enc = Cipher.encode('LOCKER 14', legend);
      expect(enc, '🌊🔑🍒🗝🌙🌧 14');
      final dec = Cipher.decode(enc, {for (final e in legend.entries) e.value: e.key});
      expect(dec, 'LOCKER 14');
    });

    test('answer matching ignores case, spaces and punctuation', () {
      expect(Cipher.matches('locker-14, if i go quiet!', 'LOCKER 14 IF I GO QUIET'), isTrue);
      expect(Cipher.matches('locker 15', 'LOCKER 14'), isFalse);
    });

    test('caesar shift decodes the story ciphers', () {
      expect(Cipher.caesar('FGBC YBBXVAT', -13), 'STOP LOOKING');
      expect(Cipher.caesar('ZDWHU', -3), 'WATER');
      expect(Cipher.caesar('HTBFWI', -5), 'COWARD');
      expect(Cipher.vigenere('WRMLTAU', 'DAM'), 'TRAITOR');
      expect(Cipher.vigenere('TRAITOR', 'DAM', encode: true), 'WRMLTAU');
      expect(Cipher.caesar('STOP LOOKING', 13), 'FGBC YBBXVAT');
    });
  });
}
