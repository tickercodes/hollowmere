/// Pure state transitions. Everything here is deterministic and unit-testable;
/// the async engine only sequences these calls.
library;

import 'game_state.dart';
import 'script.dart';

class StateConditions implements ConditionContext {
  StateConditions(this.s);
  final GameState s;
  @override
  bool hasFlag(String flag) => s.flags.contains(flag);
  @override
  bool hasEvidence(String id) => s.evidence.contains(id);
  @override
  int get evidenceCount => s.evidence.length;
  @override
  int trust(String who) => s.trustOf(who);
}

class Reducer {
  const Reducer._();

  static GameState appendMessage(GameState s, String thread, ChatMessage m,
      {bool markUnread = true}) {
    final threads = Map<String, List<ChatMessage>>.from(s.threads);
    threads[thread] = [...(threads[thread] ?? const []), m];
    final unread = Set<String>.from(s.unreadThreads);
    if (markUnread && !m.isPlayer) unread.add(thread);
    return s.copyWith(threads: threads, unreadThreads: unread);
  }

  static GameState markThreadRead(GameState s, String thread) {
    if (!s.unreadThreads.contains(thread)) return s;
    return s.copyWith(unreadThreads: Set.from(s.unreadThreads)..remove(thread));
  }

  /// Ghost message from the mirror: appears briefly then is struck through.
  /// Saved ghosts stay readable.
  static GameState strikeMessage(GameState s, String thread, String messageId) {
    final list = s.threads[thread];
    if (list == null) return s;
    final threads = Map<String, List<ChatMessage>>.from(s.threads);
    threads[thread] = [
      for (final m in list)
        if (m.id == messageId && !m.saved)
          m.copyWith(deleted: true, vanishing: false)
        else if (m.id == messageId)
          m.copyWith(vanishing: false)
        else
          m
    ];
    return s.copyWith(threads: threads);
  }

  /// Hold-to-save a vanishing message. Caps at [GameState.ghostSaveCap] per episode.
  static GameState saveVanishing(GameState s, String thread, String messageId) {
    if (s.ghostsSavedThisEpisode >= GameState.ghostSaveCap) return s;
    final list = s.threads[thread];
    if (list == null) return s;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx < 0) return s;
    final m = list[idx];
    if (m.saved || (!m.vanishing && !m.deleted)) return s;
    final threads = Map<String, List<ChatMessage>>.from(s.threads);
    final next = List<ChatMessage>.from(list);
    next[idx] = m.copyWith(saved: true, vanishing: false, deleted: false);
    threads[thread] = next;
    return s.copyWith(
      threads: threads,
      ghostsSavedThisEpisode: s.ghostsSavedThisEpisode + 1,
    );
  }

  static GameState addHint(GameState s, String puzzle) {
    final h = Map<String, int>.from(s.hintsUsed);
    h[puzzle] = (h[puzzle] ?? 0) + 1;
    return s.copyWith(hintsUsed: h);
  }

  static GameState addFail(GameState s, String puzzle) {
    final f = Map<String, int>.from(s.fails);
    f[puzzle] = (f[puzzle] ?? 0) + 1;
    return s.copyWith(fails: f);
  }

  static GameState toggleLink(GameState s, String a, String b) {
    final key = GameState.linkKey(a, b);
    final links = Set<String>.from(s.boardLinks);
    if (!links.remove(key)) links.add(key);
    return s.copyWith(boardLinks: links);
  }

  /// Applies an `effects` bag. Unknown keys throw so typos surface in tests.
  static GameState applyEffects(GameState s, Map<String, dynamic> e) {
    var out = s;
    for (final entry in e.entries) {
      final v = entry.value;
      switch (entry.key) {
        case 'flags':
          out = out.copyWith(
              flags: Set.from(out.flags)..addAll((v as List).cast<String>()));
        case 'unflag':
          out = out.copyWith(
              flags: Set.from(out.flags)..removeAll((v as List).cast<String>()));
        case 'trust':
          final t = Map<String, int>.from(out.trust);
          for (final d in (v as Map<String, dynamic>).entries) {
            t[d.key] = (t[d.key] ?? 0) + (d.value as int);
          }
          out = out.copyWith(trust: t);
        case 'evidence':
          out = out.copyWith(
              evidence: Set.from(out.evidence)..addAll((v as List).cast<String>()));
        case 'unlock_apps':
          out = out.copyWith(
              unlockedApps: Set.from(out.unlockedApps)
                ..addAll((v as List).cast<String>()));
        case 'gallery':
          final items = List<GalleryItem>.from(out.gallery);
          for (final g in (v as List).cast<Map<String, dynamic>>()) {
            final photo = g['photo'] as String;
            items.removeWhere((x) => x.photo == photo);
            items.add(GalleryItem(photo: photo, locked: g['locked'] == true));
          }
          out = out.copyWith(gallery: items);
        case 'unlock_photos':
          final ids = (v as List).cast<String>().toSet();
          out = out.copyWith(gallery: [
            for (final g in out.gallery)
              ids.contains(g.photo) ? GalleryItem(photo: g.photo, locked: false) : g
          ]);
        case 'call_log':
          out = out.copyWith(callLog: [
            ...out.callLog,
            ...(v as List)
                .cast<Map<String, dynamic>>()
                .map(CallEntry.fromJson)
          ]);
        case 'notes':
          out = out.copyWith(notes: [
            ...out.notes,
            ...(v as List).cast<Map<String, dynamic>>().map(NoteItem.fromJson)
          ]);
        case 'feed':
          out = out.copyWith(feed: [
            ...(v as List).cast<Map<String, dynamic>>().map(FeedPost.fromJson),
            ...out.feed,
          ]);
        case 'pages':
          out = out.copyWith(
              pages: Set.from(out.pages)..addAll((v as List).cast<String>()));
        case 'pins':
          out = out.copyWith(
              boardPins: Set.from(out.boardPins)
                ..addAll((v as List).cast<String>()));
        case 'contacts':
          out = out.copyWith(
              contactNames: Map.from(out.contactNames)
                ..addAll(Map<String, String>.from(v as Map)));
        case 'mirror':
          out = out.copyWith(mirrorLevel: v as int);
        case 'journal':
          out = out.copyWith(journal: [...out.journal, v as String]);
        case 'unread':
          out = out.copyWith(
              unreadThreads: Set.from(out.unreadThreads)
                ..addAll((v as List).cast<String>()));
        case 'ending':
          out = out.copyWith(ending: v as String);
        case 'hours':
          out = out.copyWith(hoursSinceRead: v as int);
        case 'siren_seconds':
          out = out.copyWith(
            sirenEndsAtMs: DateTime.now().millisecondsSinceEpoch +
                ((v as num).toInt() * 1000),
          );
        default:
          throw ArgumentError('Unknown effect "${entry.key}"');
      }
    }
    return out;
  }

  /// Evidence needed for the best ending ("The Files"). Story bible §9.
  static const bestEndingEvidence = 11;

  /// Evidence below this makes the present-day case unprovable
  /// ("Radio Silence") even when the right person is accused.
  static const minimumEvidence = 5;

  /// Trust level at which an ally will back the player when going alone.
  static const allyTrust = 2;

  /// Resolves the ending id from accumulated state. See story bible §9.
  static String resolveEnding(GameState s) {
    final accused = s.flags.contains('accused_ardis');
    final obeyedWarden = s.flags.contains('warden_obeyed_all') &&
        s.flags.contains('fork_police') &&
        !s.flags.contains('shared_evidence');
    if (obeyedWarden) return 'warden';
    if (!accused) return 'radio_silence';
    final evidence = s.evidence.length;
    final alone = s.flags.contains('fork_alone');
    final deaconBacked = s.trustOf('deacon') >= allyTrust;
    final jonahBacked = s.trustOf('jonah') >= allyTrust;
    if (alone && !deaconBacked && !jonahBacked) return 'radio_silence';
    if (evidence < minimumEvidence) return 'radio_silence';
    if (evidence >= bestEndingEvidence && (!alone || deaconBacked || jonahBacked)) {
      return 'files';
    }
    return 'high_water';
  }
}
