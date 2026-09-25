import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/content/voicemails.dart';
import 'package:hollowmere_files/core/audio.dart';

void main() {
  test('spoken voices have unique ids and captions', () {
    final ids = spokenVoices.map((v) => v.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(spokenVoices.every((v) => v.caption.isNotEmpty), isTrue);
  });

  test('spokenVoice looks up catalog ids and rejects unknowns', () {
    expect(spokenVoice('voice_still_up')?.caption, 'still up?');
    expect(spokenVoice('voice_hello'), isNull);
  });

  test('whisper captions are lines from the case', () {
    final corpus = voicemails.values
        .expand((v) => v.transcript)
        .join('\n')
        .toLowerCase();
    // Wren's last unread message is in the scripts, not a voicemail.
    const alsoCanon = ['still up?'];
    for (final line in spokenVoices) {
      final needle = line.caption.toLowerCase();
      final stripped = needle.replaceAll(RegExp(r'[.?!]+$'), '');
      final inVoicemail = corpus.contains(needle) || corpus.contains(stripped);
      final inScripts = alsoCanon.contains(needle) || alsoCanon.contains(stripped);
      expect(inVoicemail || inScripts, isTrue, reason: line.caption);
    }
  });

  test('each music mood and voice clip has a bundled m4a', () {
    final ids = [
      ...musicAssets.values,
      ...spokenVoices.map((v) => v.id),
      'voice_radio',
      'voice_static',
    ];
    for (final id in ids) {
      expect(File('assets/audio/$id.m4a').existsSync(), isTrue, reason: id);
    }
    expect(File('assets/audio/music_bed.m4a').existsSync(), isFalse);
    expect(File('assets/audio/ATTRIBUTION.md').existsSync(), isTrue);
  });
}
