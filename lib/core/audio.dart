import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/voices.dart';
import 'whisper.dart';

export '../content/voices.dart';

/// Which looping score is under the phone.
enum MusicMood { menu, play, scene, ending }

const musicAssets = <MusicMood, String>{
  MusicMood.menu: 'music_menu',
  MusicMood.play: 'music_play',
  MusicMood.scene: 'music_scene',
  MusicMood.ending: 'music_echoes',
};

/// Thin wrapper over just_audio: short SFX on a pool of players, looping
/// background music that changes with the story, interstitial voices, and
/// one voicemail player for forensics.
/// All failures are swallowed - audio must never block the story.
class AudioService {
  AudioService({this.enabled = true}) {
    _vmSub = voicemail.playerStateStream.listen((s) {
      _voicemailDuck = s.playing;
      unawaited(_applyMusicVolume());
    });
    _voiceSub = _voice.playerStateStream.listen((s) {
      _voiceDuck = s.playing;
      unawaited(_applyMusicVolume());
    });
  }

  bool enabled;
  bool voicesEnabled = true;
  double musicIntensity = 0.45;

  final _sfxPool = List.generate(4, (_) => AudioPlayer());
  int _next = 0;
  final voicemail = AudioPlayer();
  final _music = AudioPlayer();
  final _voice = AudioPlayer();
  final _oneshot = AudioPlayer();
  StreamSubscription<PlayerState>? _vmSub;
  StreamSubscription<PlayerState>? _voiceSub;
  bool _voicemailDuck = false;
  bool _voiceDuck = false;
  bool _musicReady = false;
  MusicMood? _mood;
  String? _musicAsset;
  Timer? _captionTimer;
  final _rng = Random();

  static const _intensityKey = 'hollowmere.musicIntensity';
  static const _voicesKey = 'hollowmere.voicesEnabled';
  static String path(String id) => 'assets/audio/$id.m4a';

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
      voicesEnabled = prefs.getBool(_voicesKey) ?? true;
      await _applyMusicVolume();
      if (_musicReady && musicIntensity > 0 && !_music.playing) {
        await _music.play();
      }
    } on Object catch (e) {
      debugPrint('music start failed: $e');
    }
  }

  Future<void> setMood(MusicMood mood) async {
    final asset = musicAssets[mood]!;
    if (_mood == mood && _musicAsset == asset && _musicReady) {
      if (musicIntensity > 0 && !_music.playing) {
        await _applyMusicVolume();
        await _music.play();
      }
      return;
    }
    _mood = mood;
    _musicAsset = asset;
    try {
      await _music.setLoopMode(LoopMode.one);
      await _music.setAsset(path(asset));
      _musicReady = true;
      await _applyMusicVolume();
      if (musicIntensity > 0) {
        await _music.play();
      } else {
        await _music.pause();
      }
    } on Object catch (e) {
      debugPrint('music $asset failed: $e');
    }
  }

  void setMusicIntensity(double v) {
    musicIntensity = v.clamp(0, 1);
    unawaited(_commitPrefs());
    unawaited(_applyMusicVolume());
    if (musicIntensity <= 0) {
      unawaited(_music.pause());
    } else if (_musicReady && !_music.playing) {
      unawaited(_music.play());
    }
  }

  void setVoicesEnabled(bool v) {
    voicesEnabled = v;
    unawaited(_commitPrefs());
    if (!v) {
      unawaited(_voice.stop());
      unawaited(_oneshot.stop());
      _clearCaption();
    }
  }

  /// Play one scripted line. [id] must be a [spokenVoices] entry; unknown ids
  /// are ignored. Nothing plays unless a story node asked for this beat.
  Future<void> playVoice(String id) async {
    if (!voicesEnabled || _voicemailDuck) return;
    final line = spokenVoice(id);
    if (line == null) return;
    _showCaption(line);
    try {
      await _voice.setVolume(0.88);
      await _voice.setAsset(path(line.id));
      await _voice.play();
    } on Object catch (e) {
      debugPrint('voice ${line.id} failed: $e');
    }
  }

  /// Radio texture only. Spoken lines come from scripted `voice` fields.
  Future<void> onGlitch() async {
    if (!voicesEnabled) return;
    await _playOneShot(
      _rng.nextBool() ? 'voice_static' : 'voice_radio',
      volume: 0.55,
    );
  }

  void _showCaption(VoiceLine line) {
    whisperListenable.value = WhisperEvent(line.caption);
    _captionTimer?.cancel();
    final ms = (2200 + line.caption.length * 55).clamp(2400, 7000);
    _captionTimer = Timer(Duration(milliseconds: ms), () {
      if (whisperListenable.value?.caption == line.caption) {
        _clearCaption();
      }
    });
  }

  void _clearCaption() {
    whisperListenable.value = null;
  }

  Future<void> _playOneShot(String id, {double volume = 1}) async {
    try {
      await _oneshot.setVolume(volume);
      await _oneshot.setAsset(path(id));
      await _oneshot.play();
    } on Object catch (e) {
      debugPrint('oneshot $id failed: $e');
    }
  }

  Future<void> _commitPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_intensityKey, musicIntensity);
      await prefs.setBool(_voicesKey, voicesEnabled);
    } on Object catch (e) {
      debugPrint('audio prefs failed: $e');
    }
  }

  Future<void> _applyMusicVolume() async {
    final duck = _voicemailDuck
        ? 0.16
        : _voiceDuck
            ? 0.28
            : 1.0;
    try {
      await _music.setVolume(musicIntensity * duck);
    } on Object catch (e) {
      debugPrint('music volume failed: $e');
    }
  }

  void dispose() {
    unawaited(_vmSub?.cancel());
    unawaited(_voiceSub?.cancel());
    _captionTimer?.cancel();
    _clearCaption();
    for (final p in _sfxPool) {
      p.dispose();
    }
    voicemail.dispose();
    _music.dispose();
    _voice.dispose();
    _oneshot.dispose();
  }
}

final audioProvider = Provider<AudioService>((ref) {
  final a = AudioService();
  ref.onDispose(a.dispose);
  return a;
});
