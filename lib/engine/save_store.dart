import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_state.dart';

/// Persists the single save slot. Synchronous reads keep engine startup simple;
/// the async write is fire-and-forget behind a debounce in the engine.
abstract class SaveStore {
  GameState? load();
  Future<void> save(GameState state);
  Future<void> clear();
}

class PrefsSaveStore implements SaveStore {
  PrefsSaveStore(this._prefs);
  static const _key = 'hollowmere.save.v1';
  final SharedPreferences _prefs;

  static Future<PrefsSaveStore> open() async =>
      PrefsSaveStore(await SharedPreferences.getInstance());

  @override
  GameState? load() {
    final json = _prefs.getString(_key);
    if (json == null) return null;
    try {
      return GameState.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      // A corrupt save must never brick the app; start fresh instead.
      return null;
    }
  }

  @override
  Future<void> save(GameState state) =>
      _prefs.setString(_key, jsonEncode(state.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}

class MemorySaveStore implements SaveStore {
  GameState? _state;
  @override
  GameState? load() => _state;
  @override
  Future<void> save(GameState state) async => _state = state;
  @override
  Future<void> clear() async => _state = null;
}
