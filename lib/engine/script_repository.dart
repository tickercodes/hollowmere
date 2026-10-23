import 'package:flutter/services.dart' show rootBundle;

import 'script.dart';

/// All episode scripts, loaded once at startup.
class ScriptRepository {
  ScriptRepository(Map<String, EpisodeScript> episodes) : _episodes = episodes;

  static const episodeIds = ['ep1', 'ep2', 'ep3', 'ep4', 'ep5', 'ep6', 'ep7', 'ep8', 'ep9', 'ep10', 'ep11', 'ep12', 'ep13', 'ep14', 'ep15', 'ep16', 'ep17', 'ep18', 'ep19', 'ep20'];

  final Map<String, EpisodeScript> _episodes;

  EpisodeScript episode(String id) {
    final ep = _episodes[id];
    if (ep == null) throw StateError('Episode "$id" is not loaded');
    return ep;
  }

  List<EpisodeScript> get all =>
      _episodes.values.toList()..sort((a, b) => a.number.compareTo(b.number));

  static Future<ScriptRepository> loadFromAssets() async {
    final map = <String, EpisodeScript>{};
    for (final id in episodeIds) {
      final source = await rootBundle.loadString('assets/story/$id.json');
      map[id] = EpisodeScript.fromJsonString(source);
    }
    return ScriptRepository(map);
  }
}
