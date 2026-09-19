import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over just_audio: short SFX on a pool of players, looping
/// background music, and one voicemail player for forensics.
/// All failures are swallowed - audio must never block the story.
class AudioService {
  AudioService({this.enabled = true}) {
    _vmSub = voicemail.playerStateStream.listen((s) {
      _voicemailDuck = s.playing;
      unawaited(_applyMusicVolume());
    });
  }

  bool enabled;
  double musicIntensity = 0.45;

  final _sfxPool = List.generate(4, (_) => AudioPlayer());
  int _next = 0;
  final voicemail = AudioPlayer();
  final _music = AudioPlayer();
  StreamSubscription<PlayerState>? _vmSub;
  bool _voicemailDuck = false;
  bool _musicReady = false;

  static const _intensityKey = 'hollowmere.musicIntensity';
  static String path(String id) => 'assets/audio/$id.m4a';
  // music_bed: CC0 "Lost in a bad place" by congusbongus (OpenGameArt).

  Future<void> sfx(String id) async {
    if (!enabled) return;
    final p = _sfxPool[_next++ % _sfxPool.length];
    try {
      await p.setAsset(path('sfx_$id'));
      await p.play();
    } on Object catch (e) {
      debugPrint('sfx $id failed: $e');
    }
  }

  /// Which clip the shared voicemail player currently holds.
  String? currentVoicemail;

  Future<Duration?> loadVoicemail(String id) async {
    try {
      currentVoicemail = id;
      return await voicemail.setAsset(path(id));
    } on Object catch (e) {
      debugPrint('voicemail $id failed: $e');
      return null;
    }
  }

  void setEnabled(bool v) {
    enabled = v;
  }

  Future<void> startMusic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      musicIntensity = (prefs.getDouble(_intensityKey) ?? 0.45).clamp(0, 1);
      if (!_musicReady) {
        await _music.setLoopMode(LoopMode.one);
        await _music.setAsset(path('music_bed'));
        _musicReady = true;
      }
      await _applyMusicVolume();
      if (musicIntensity > 0 && !_music.playing) {
        await _music.play();
      }
    } on Object catch (e) {
      debugPrint('music bed failed: $e');
    }
  }

  void setMusicIntensity(double v) {
    musicIntensity = v.clamp(0, 1);
    unawaited(_commitMusicIntensity());
  }

  Future<void> _commitMusicIntensity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_intensityKey, musicIntensity);
    } on Object catch (e) {
      debugPrint('music intensity persist failed: $e');
    }
    await _applyMusicVolume();
    if (musicIntensity <= 0) {
      await _music.pause();
    } else if (_musicReady && !_music.playing) {
      await _music.play();
    }
  }

  Future<void> _applyMusicVolume() async {
    final duck = _voicemailDuck ? 0.18 : 1.0;
    try {
      await _music.setVolume(musicIntensity * duck);
    } on Object catch (e) {
      debugPrint('music volume failed: $e');
    }
  }

  void dispose() {
    unawaited(_vmSub?.cancel());
    for (final p in _sfxPool) {
      p.dispose();
    }
    voicemail.dispose();
    _music.dispose();
  }
}

final audioProvider = Provider<AudioService>((ref) {
  final a = AudioService();
  ref.onDispose(a.dispose);
  return a;
});
