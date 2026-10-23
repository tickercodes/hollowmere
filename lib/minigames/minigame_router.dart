import 'package:flutter/material.dart';

import '../engine/story_engine.dart';
import 'audio_tag_game.dart';
import 'board_connect_game.dart';
import 'cipher_game.dart';
import 'key_cipher_game.dart';
import 'feed_scrub_game.dart';
import 'live_static_game.dart';
import 'log_diff_game.dart';
import 'order_game.dart';
import 'passcode_game.dart';
import 'photo_spot_game.dart';
import 'sudoku_game.dart';

import 'wire_cut_game.dart';
import 'signal_hack_game.dart';

/// Every mini-game id a script may reference. Kept as a constant so the
/// script validator (and tests) can reject unknown games at load time.
const minigameIds = {
  'passcode',
  'photo_spot',
  'order',
  'cipher',
  'key_cipher',
  'sudoku',
  'audio_tag',
  'feed_scrub',
  'board_connect',
  'live_static',
  'log_diff',
  'voice_match',
  'accuse',
  'wire_cut',
  'signal_hack',
};

class MinigameRouter extends StatelessWidget {
  const MinigameRouter({super.key, required this.interaction});
  final MinigameInteraction interaction;

  @override
  Widget build(BuildContext context) => switch (interaction.game) {
        'passcode' => PasscodeGame(interaction: interaction),
        'photo_spot' => PhotoSpotGame(interaction: interaction),
        'order' => OrderGame(interaction: interaction),
        'cipher' => CipherGame(interaction: interaction),
        'key_cipher' => KeyCipherGame(interaction: interaction),
        'sudoku' => SudokuGame(interaction: interaction),
        'audio_tag' => AudioTagGame(interaction: interaction),
        'feed_scrub' => FeedScrubGame(interaction: interaction),
        'board_connect' => BoardConnectGame(interaction: interaction),
        'live_static' => LiveStaticGame(interaction: interaction),
        'log_diff' => LogDiffGame(interaction: interaction),
        'voice_match' => VoiceMatchGame(interaction: interaction),
        'accuse' => AccuseGame(interaction: interaction),
        'wire_cut' => WireCutGame(interaction: interaction),
        'signal_hack' => SignalHackGame(interaction: interaction),
        _ => throw StateError('Unknown minigame "${interaction.game}"'),
      };
}
