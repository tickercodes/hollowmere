/// Immutable, serialisable snapshot of everything the player has done.
///
/// The story engine produces new [GameState] values; the UI only reads them.
/// Every collection is treated as read-only; use [copyWith] to derive changes.
library;

import 'dart:collection';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    this.image,
    this.deleted = false,
    this.vanishing = false,
    this.saved = false,
  });

  /// Unique within a thread; used for read tracking and animations.
  final String id;

  /// Character id, or `player` for Sam.
  final String from;
  final String text;

  /// Evidence/photo id rendered inline.
  final String? image;

  /// Ghost messages from the mirror: shown, then struck through.
  final bool deleted;

  /// Still on screen, about to vanish unless the player holds to save.
  final bool vanishing;

  /// Held before the mirror ate it. Stays readable.
  final bool saved;

  bool get isPlayer => from == 'player';

  ChatMessage copyWith({
    bool? deleted,
    bool? vanishing,
    bool? saved,
  }) =>
      ChatMessage(
        id: id,
        from: from,
        text: text,
        image: image,
        deleted: deleted ?? this.deleted,
        vanishing: vanishing ?? this.vanishing,
        saved: saved ?? this.saved,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'text': text,
        if (image != null) 'image': image,
        if (deleted) 'deleted': true,
        if (vanishing) 'vanishing': true,
        if (saved) 'saved': true,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        from: j['from'] as String,
        text: j['text'] as String,
        image: j['image'] as String?,
        deleted: j['deleted'] == true,
        vanishing: j['vanishing'] == true,
        saved: j['saved'] == true,
      );
}

class CallEntry {
  const CallEntry({
    required this.id,
    required this.contact,
    required this.direction,
    required this.label,
    this.durationSeconds,
    this.voicemail,
  });

  final String id;
  final String contact;

  /// `in`, `out`, or `missed`.
  final String direction;

  /// Display timestamp such as "Tue 11:52 PM".
  final String label;
  final int? durationSeconds;

  /// Audio asset id for a voicemail attached to this entry.
  final String? voicemail;

  Map<String, dynamic> toJson() => {
        'id': id,
        'contact': contact,
        'direction': direction,
        'label': label,
        if (durationSeconds != null) 'duration': durationSeconds,
        if (voicemail != null) 'voicemail': voicemail,
      };

  factory CallEntry.fromJson(Map<String, dynamic> j) => CallEntry(
        id: j['id'] as String,
        contact: j['contact'] as String,
        direction: j['direction'] as String,
        label: j['label'] as String,
        durationSeconds: j['duration'] as int?,
        voicemail: j['voicemail'] as String?,
      );
}

class GalleryItem {
  const GalleryItem({required this.photo, required this.locked});

  /// Photo id from the photo registry.
  final String photo;
  final bool locked;

  Map<String, dynamic> toJson() => {'photo': photo, 'locked': locked};

  factory GalleryItem.fromJson(Map<String, dynamic> j) =>
      GalleryItem(photo: j['photo'] as String, locked: j['locked'] == true);
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.text,
    required this.timeLabel,
    this.image,
    this.deleted = false,
    this.cachedText,
  });

  final String id;
  final String author;
  final String text;
  final String timeLabel;
  final String? image;
  final bool deleted;

  /// What an archive crawler saw before the post was edited/deleted.
  final String? cachedText;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'time': timeLabel,
        if (image != null) 'image': image,
        if (deleted) 'deleted': true,
        if (cachedText != null) 'cached': cachedText,
      };

  factory FeedPost.fromJson(Map<String, dynamic> j) => FeedPost(
        id: j['id'] as String,
        author: j['author'] as String,
        text: j['text'] as String,
        timeLabel: j['time'] as String,
        image: j['image'] as String?,
        deleted: j['deleted'] == true,
        cachedText: j['cached'] as String?,
      );
}

class NoteItem {
  const NoteItem({required this.id, required this.title, required this.body});
  final String id;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};
  factory NoteItem.fromJson(Map<String, dynamic> j) => NoteItem(
      id: j['id'] as String, title: j['title'] as String, body: j['body'] as String);
}

/// What the player must do next. Drives the objective banner and highlights.
class Objective {
  const Objective({required this.text, required this.target});
  final String text;

  /// e.g. `{"app": "gallery"}`, `{"photo": "dock_night"}`, `{"thread": "jonah"}`.
  final Map<String, String> target;

  Map<String, dynamic> toJson() => {'text': text, 'target': target};
  factory Objective.fromJson(Map<String, dynamic> j) => Objective(
        text: j['text'] as String,
        target: Map<String, String>.from(j['target'] as Map),
      );
}

class GameState {
  GameState({
    this.playerName = 'Sam',
    this.episodeId = 'ep1',
    this.nodeId,
    Set<String>? flags,
    Map<String, int>? trust,
    Set<String>? evidence,
    Map<String, List<ChatMessage>>? threads,
    Set<String>? unlockedApps,
    List<GalleryItem>? gallery,
    List<CallEntry>? callLog,
    List<NoteItem>? notes,
    List<FeedPost>? feed,
    Set<String>? pages,
    Set<String>? boardPins,
    Set<String>? boardLinks,
    Map<String, String>? contactNames,
    Map<String, int>? hintsUsed,
    Map<String, int>? fails,
    Set<String>? unreadThreads,
    Set<String>? completedEpisodes,
    this.objective,
    this.mirrorLevel = 0,
    this.ending,
    this.textSpeed = 1.4,
    this.hoursSinceRead = 264,
    this.ghostsSavedThisEpisode = 0,
    this.sirenEndsAtMs,
    List<String>? journal,
  })  : flags = UnmodifiableSetView(flags ?? {}),
        trust = UnmodifiableMapView(trust ?? {}),
        evidence = UnmodifiableSetView(evidence ?? {}),
        threads = UnmodifiableMapView(threads ?? {}),
        unlockedApps = UnmodifiableSetView(unlockedApps ?? {'messages'}),
        gallery = UnmodifiableListView(gallery ?? []),
        callLog = UnmodifiableListView(callLog ?? []),
        notes = UnmodifiableListView(notes ?? []),
        feed = UnmodifiableListView(feed ?? []),
        pages = UnmodifiableSetView(pages ?? {}),
        boardPins = UnmodifiableSetView(boardPins ?? {}),
        boardLinks = UnmodifiableSetView(boardLinks ?? {}),
        contactNames = UnmodifiableMapView(contactNames ?? {}),
        hintsUsed = UnmodifiableMapView(hintsUsed ?? {}),
        fails = UnmodifiableMapView(fails ?? {}),
        unreadThreads = UnmodifiableSetView(unreadThreads ?? {}),
        completedEpisodes = UnmodifiableSetView(completedEpisodes ?? {}),
        journal = UnmodifiableListView(journal ?? []);

  final String playerName;
  final String episodeId;

  /// Null before an episode starts (title/menu state).
  final String? nodeId;
  final Set<String> flags;
  final Map<String, int> trust;
  final Set<String> evidence;
  final Map<String, List<ChatMessage>> threads;
  final Set<String> unlockedApps;
  final List<GalleryItem> gallery;
  final List<CallEntry> callLog;
  final List<NoteItem> notes;
  final List<FeedPost> feed;

  /// Browser pages the player has discovered (by id).
  final Set<String> pages;
  final Set<String> boardPins;

  /// Canonical "a|b" with a < b.
  final Set<String> boardLinks;

  /// Dynamic display names, e.g. an unknown number resolving to Ardis.
  final Map<String, String> contactNames;
  final Map<String, int> hintsUsed;
  final Map<String, int> fails;
  final Set<String> unreadThreads;
  final Set<String> completedEpisodes;
  final Objective? objective;

  /// 0..3, how much of Wren's phone has "stabilised" onto Sam's.
  final int mirrorLevel;
  final String? ending;
  final double textSpeed;

  /// Short recap lines appended as the story progresses.
  final List<String> journal;

  /// Lock-screen counter. Starts at 264 (11 days) and climbs until she reads.
  final int hoursSinceRead;

  /// Vanishing messages saved this episode (cap 5).
  final int ghostsSavedThisEpisode;

  /// Wall-clock ms when the Episode 6 siren sounds. Null until the countdown starts.
  final int? sirenEndsAtMs;

  int trustOf(String who) => trust[who] ?? 0;
  bool has(String flag) => flags.contains(flag);
  int get evidenceCount => evidence.length;
  static const ghostSaveCap = 5;

  static String linkKey(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

  GameState copyWith({
    String? playerName,
    String? episodeId,
    String? nodeId,
    bool clearNode = false,
    Set<String>? flags,
    Map<String, int>? trust,
    Set<String>? evidence,
    Map<String, List<ChatMessage>>? threads,
    Set<String>? unlockedApps,
    List<GalleryItem>? gallery,
    List<CallEntry>? callLog,
    List<NoteItem>? notes,
    List<FeedPost>? feed,
    Set<String>? pages,
    Set<String>? boardPins,
    Set<String>? boardLinks,
    Map<String, String>? contactNames,
    Map<String, int>? hintsUsed,
    Map<String, int>? fails,
    Set<String>? unreadThreads,
    Set<String>? completedEpisodes,
    Objective? objective,
    bool clearObjective = false,
    int? mirrorLevel,
    String? ending,
    double? textSpeed,
    int? hoursSinceRead,
    int? ghostsSavedThisEpisode,
    int? sirenEndsAtMs,
    bool clearSiren = false,
    List<String>? journal,
  }) =>
      GameState(
        playerName: playerName ?? this.playerName,
        episodeId: episodeId ?? this.episodeId,
        nodeId: clearNode ? null : (nodeId ?? this.nodeId),
        flags: flags ?? this.flags,
        trust: trust ?? this.trust,
        evidence: evidence ?? this.evidence,
        threads: threads ?? this.threads,
        unlockedApps: unlockedApps ?? this.unlockedApps,
        gallery: gallery ?? this.gallery,
        callLog: callLog ?? this.callLog,
        notes: notes ?? this.notes,
        feed: feed ?? this.feed,
        pages: pages ?? this.pages,
        boardPins: boardPins ?? this.boardPins,
        boardLinks: boardLinks ?? this.boardLinks,
        contactNames: contactNames ?? this.contactNames,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        fails: fails ?? this.fails,
        unreadThreads: unreadThreads ?? this.unreadThreads,
        completedEpisodes: completedEpisodes ?? this.completedEpisodes,
        objective: clearObjective ? null : (objective ?? this.objective),
        mirrorLevel: mirrorLevel ?? this.mirrorLevel,
        ending: ending ?? this.ending,
        textSpeed: textSpeed ?? this.textSpeed,
        hoursSinceRead: hoursSinceRead ?? this.hoursSinceRead,
        ghostsSavedThisEpisode: ghostsSavedThisEpisode ?? this.ghostsSavedThisEpisode,
        sirenEndsAtMs: clearSiren ? null : (sirenEndsAtMs ?? this.sirenEndsAtMs),
        journal: journal ?? this.journal,
      );

  Map<String, dynamic> toJson() => {
        'v': 1,
        'playerName': playerName,
        'episodeId': episodeId,
        'nodeId': nodeId,
        'flags': flags.toList(),
        'trust': trust,
        'evidence': evidence.toList(),
        'threads': {
          for (final e in threads.entries)
            e.key: e.value.map((m) => m.toJson()).toList()
        },
        'unlockedApps': unlockedApps.toList(),
        'gallery': gallery.map((g) => g.toJson()).toList(),
        'callLog': callLog.map((c) => c.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'feed': feed.map((f) => f.toJson()).toList(),
        'pages': pages.toList(),
        'boardPins': boardPins.toList(),
        'boardLinks': boardLinks.toList(),
        'contactNames': contactNames,
        'hintsUsed': hintsUsed,
        'fails': fails,
        'unreadThreads': unreadThreads.toList(),
        'completedEpisodes': completedEpisodes.toList(),
        'objective': objective?.toJson(),
        'mirrorLevel': mirrorLevel,
        'ending': ending,
        'textSpeed': textSpeed,
        'hoursSinceRead': hoursSinceRead,
        'ghostsSavedThisEpisode': ghostsSavedThisEpisode,
        'sirenEndsAtMs': sirenEndsAtMs,
        'journal': journal,
      };

  factory GameState.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] as List?) ?? []).map((e) => f(e as Map<String, dynamic>)).toList();
    Set<String> set(String k) => Set<String>.from((j[k] as List?) ?? []);
    Map<String, int> ints(String k) =>
        Map<String, int>.from((j[k] as Map?) ?? {});
    return GameState(
      playerName: j['playerName'] as String? ?? 'Sam',
      episodeId: j['episodeId'] as String? ?? 'ep1',
      nodeId: j['nodeId'] as String?,
      flags: set('flags'),
      trust: ints('trust'),
      evidence: set('evidence'),
      threads: {
        for (final e in ((j['threads'] as Map?) ?? {}).entries)
          e.key as String: (e.value as List)
              .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList()
      },
      unlockedApps: set('unlockedApps'),
      gallery: list('gallery', GalleryItem.fromJson),
      callLog: list('callLog', CallEntry.fromJson),
      notes: list('notes', NoteItem.fromJson),
      feed: list('feed', FeedPost.fromJson),
      pages: set('pages'),
      boardPins: set('boardPins'),
      boardLinks: set('boardLinks'),
      contactNames: Map<String, String>.from((j['contactNames'] as Map?) ?? {}),
      hintsUsed: ints('hintsUsed'),
      fails: ints('fails'),
      unreadThreads: set('unreadThreads'),
      completedEpisodes: set('completedEpisodes'),
      objective: j['objective'] == null
          ? null
          : Objective.fromJson(j['objective'] as Map<String, dynamic>),
      mirrorLevel: j['mirrorLevel'] as int? ?? 0,
      ending: j['ending'] as String?,
      textSpeed: (j['textSpeed'] as num?)?.toDouble() ?? 1.4,
      hoursSinceRead: j['hoursSinceRead'] as int? ?? 264,
      ghostsSavedThisEpisode: j['ghostsSavedThisEpisode'] as int? ?? 0,
      sirenEndsAtMs: j['sirenEndsAtMs'] as int?,
      journal: List<String>.from((j['journal'] as List?) ?? []),
    );
  }
}
