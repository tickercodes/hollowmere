/// Episode scripts are JSON documents in `assets/story/`. This file turns them
/// into typed-enough objects and validates their graph so authoring mistakes
/// fail in tests rather than mid-game.
library;

import 'dart:convert';

class StoryNode {
  StoryNode(this.id, this.raw);
  final String id;
  final Map<String, dynamic> raw;

  String get type => raw['type'] as String;
  String? get next => raw['next'] as String?;
  dynamic operator [](String key) => raw[key];

  Map<String, dynamic> get effects =>
      (raw['effects'] as Map<String, dynamic>?) ?? const {};
  List<Map<String, dynamic>> get options =>
      ((raw['options'] as List?) ?? const []).cast<Map<String, dynamic>>();
  List<String> get hints =>
      ((raw['hints'] as List?) ?? const []).cast<String>();
  Map<String, dynamic> get config {
    final rawConfig = raw['config'];
    if (rawConfig is! Map) return const {};
    final cfg = Map<String, dynamic>.from(rawConfig);
    cfg['cipher'] ??= cfg['ciphertext'];
    cfg.putIfAbsent('legend', () => <String, String>{});
    return cfg;
  }
}

class EpisodeScript {
  EpisodeScript({
    required this.id,
    required this.number,
    required this.title,
    required this.start,
    required this.nodes,
  });

  final String id;
  final int number;
  final String title;
  final String start;
  final Map<String, StoryNode> nodes;

  StoryNode node(String id) {
    final n = nodes[id];
    if (n == null) throw StateError('Unknown node "$id" in $this');
    return n;
  }

  factory EpisodeScript.fromJsonString(String source) =>
      EpisodeScript.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory EpisodeScript.fromJson(Map<String, dynamic> j) {
    final nodes = <String, StoryNode>{};
    for (final e in (j['nodes'] as Map<String, dynamic>).entries) {
      nodes[e.key] = StoryNode(e.key, e.value as Map<String, dynamic>);
    }
    return EpisodeScript(
      id: j['id'] as String,
      number: j['number'] as int,
      title: j['title'] as String,
      start: j['start'] as String,
      nodes: nodes,
    );
  }

  static const nodeTypes = {
    'title', 'message', 'choice', 'notification', 'goal', 'minigame', 'call',
    'scene', 'glitch', 'effects', 'branch', 'delay', 'end_episode', 'ending',
  };

  /// Returns human-readable problems; empty when the script is well-formed.
  List<String> validate() {
    final problems = <String>[];
    if (!nodes.containsKey(start)) problems.add('start "$start" missing');

    void check(String? target, String from) {
      if (target == null) return;
      if (!nodes.containsKey(target)) {
        problems.add('node "$from" points to missing "$target"');
      }
    }

    for (final n in nodes.values) {
      if (!nodeTypes.contains(n.type)) {
        problems.add('node "${n.id}" has unknown type "${n.type}"');
        continue;
      }
      switch (n.type) {
        case 'choice':
          if (n.options.isEmpty) problems.add('choice "${n.id}" has no options');
          for (final o in n.options) {
            check(o['next'] as String?, n.id);
          }
        case 'branch':
          check(n['then'] as String?, n.id);
          check(n['else'] as String?, n.id);
        case 'call':
          final script = (n['script'] as List?) ?? const [];
          if (script.isEmpty) problems.add('call "${n.id}" has empty script');
          for (final item in script.cast<Map<String, dynamic>>()) {
            for (final o in ((item['choice'] as List?) ?? const [])
                .cast<Map<String, dynamic>>()) {
              final goto = o['goto'];
              if (goto is int && (goto < 0 || goto >= script.length)) {
                problems.add('call "${n.id}" goto $goto out of range');
              }
            }
          }
          check(n.next, n.id);
        case 'end_episode':
        case 'ending':
          break;
        default:
          if (n.next == null) problems.add('node "${n.id}" has no next');
          check(n.next, n.id);
      }
    }
    return problems;
  }

  @override
  String toString() => 'EpisodeScript($id)';
}

/// Declarative conditions used by `branch` nodes and option visibility.
///
/// Supported shapes:
/// `{"flag": "x"}`, `{"not_flag": "x"}`, `{"trust": {"who": "jonah", "min": 2}}`,
/// `{"trust": {"who": "jonah", "max": 1}}`, `{"evidence_min": 5}`,
/// `{"has_evidence": "id"}`, `{"all": [...]}`, `{"any": [...]}`.
class Condition {
  static bool evaluate(Map<String, dynamic>? c, ConditionContext ctx) {
    if (c == null || c.isEmpty) return true;
    if (c.containsKey('all')) {
      return (c['all'] as List)
          .every((e) => evaluate(e as Map<String, dynamic>, ctx));
    }
    if (c.containsKey('any')) {
      return (c['any'] as List)
          .any((e) => evaluate(e as Map<String, dynamic>, ctx));
    }
    if (c.containsKey('flag')) return ctx.hasFlag(c['flag'] as String);
    if (c.containsKey('not_flag')) return !ctx.hasFlag(c['not_flag'] as String);
    if (c.containsKey('has_evidence')) {
      return ctx.hasEvidence(c['has_evidence'] as String);
    }
    if (c.containsKey('evidence_min')) {
      return ctx.evidenceCount >= (c['evidence_min'] as int);
    }
    if (c.containsKey('trust')) {
      final t = c['trust'] as Map<String, dynamic>;
      final v = ctx.trust(t['who'] as String);
      if (t.containsKey('min') && v < (t['min'] as int)) return false;
      if (t.containsKey('max') && v > (t['max'] as int)) return false;
      return true;
    }
    throw ArgumentError('Unknown condition $c');
  }
}

abstract class ConditionContext {
  bool hasFlag(String flag);
  bool hasEvidence(String id);
  int get evidenceCount;
  int trust(String who);
}
