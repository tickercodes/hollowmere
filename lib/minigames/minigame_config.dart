/// Normalizes the two config dialects used in episode scripts:
/// the original object-based shapes (ep1–6) and the later string-list /
/// alternate-key shapes (ep7+).
library;

import '../content/voicemails.dart';

class MinigameConfig {
  const MinigameConfig._();

  static List<Map<String, dynamic>> orderItems(Map<String, dynamic> cfg) {
    final raw = (cfg['items'] as List?) ?? const [];
    return [
      for (final item in raw)
        if (item is Map)
          Map<String, dynamic>.from(item)
        else
          {'id': '$item', 'text': '$item'},
    ];
  }

  static List<String> orderAnswer(Map<String, dynamic> cfg) {
    final raw = cfg['answer'] ?? cfg['correct'];
    if (raw is! List) return const [];
    return raw.map((e) => e is Map ? '${e['id']}' : '$e').toList();
  }

  static String photoId(Map<String, dynamic> cfg) {
    final raw = '${cfg['photo'] ?? cfg['image'] ?? ''}';
    return photoAliases[raw] ?? raw;
  }

  static List<Map<String, dynamic>> logRows(Map<String, dynamic> cfg) {
    final rows = cfg['rows'];
    if (rows is List && rows.isNotEmpty) {
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final left = '${cfg['left'] ?? ''}'.split('\n');
    final right = '${cfg['right'] ?? ''}'.split('\n');
    final n = left.length > right.length ? left.length : right.length;
    return [
      for (var i = 0; i < n; i++)
        {
          'time': '${i + 1}',
          'left': i < left.length && left[i].isNotEmpty ? left[i] : '—',
          'right': i < right.length && right[i].isNotEmpty ? right[i] : '—',
          'mismatch': (i < left.length ? left[i] : '') !=
              (i < right.length ? right[i] : ''),
        },
    ];
  }

  static List<List<String>> boardRequired(Map<String, dynamic> cfg) {
    final required = cfg['required'];
    if (required is List && required.isNotEmpty) {
      return [
        for (final pair in required)
          if (pair is List) pair.map((e) => '$e').toList(),
      ];
    }
    final connections = cfg['connections'];
    if (connections is List) {
      return [
        for (final c in connections)
          if (c is Map) ['${c['from']}', '${c['to']}'],
      ];
    }
    return const [];
  }

  static List<Map<String, dynamic>> liveSteps(Map<String, dynamic> cfg) {
    final steps = cfg['steps'];
    if (steps is List) {
      return steps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  static double? tuneFrequency(Map<String, dynamic> cfg) {
    final v = cfg['frequency'] ?? cfg['target_freq'];
    if (v is num) return v.toDouble();
    return null;
  }

  static String? scrubTime(Map<String, dynamic> cfg) {
    final v = cfg['target_time'] ?? cfg['targetTime'];
    return v is String && v.contains(':') ? v : null;
  }

  static List<Map<String, dynamic>> voiceClips(Map<String, dynamic> cfg) {
    final clips = cfg['clips'];
    if (clips is List && clips.isNotEmpty) {
      return clips.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final voicemail = cfg['voicemail'] as String? ?? 'vm_unknown';
    final target = cfg['target'] as String?;
    final answer = cfg['answer'] as String? ??
        (target != null && !target.startsWith('voice_') ? target : 'caleb');
    if (!voicemails.containsKey(voicemail)) return const [];
    return [
      {'voicemail': voicemail, 'answer': answer},
    ];
  }

  static List<String> voiceOptions(Map<String, dynamic> cfg) {
    final options = cfg['options'];
    if (options is List && options.isNotEmpty) {
      return options.cast<String>();
    }
    final clips = voiceClips(cfg);
    final answer = clips.isEmpty ? 'caleb' : '${clips.first['answer']}';
    final fallback = ['caleb', 'deacon', 'jonah', 'ardis'];
    if (!fallback.contains(answer)) fallback.insert(0, answer);
    return fallback;
  }
}

const photoAliases = {
  'ev_drowned_orchard': 'relay_field',
  'ev_inspection_report': 'inspection_report',
  'ev_underwater_church': 'underwater_church',
  'ev_server_farm': 'server_farm',
  'loc_town_hall_archive': 'loc_archive',
  'loc_server_farm': 'server_farm',
};
