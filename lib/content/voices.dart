/// Scripted interstitial lines. Ids are what episode JSON may set as `"voice"`.
class VoiceLine {
  const VoiceLine(this.id, this.caption);
  final String id;
  final String caption;
}

/// Every caption is a line the player also meets in-story. Played only when
/// a node opts in, at the beat where that line is already live.
const spokenVoices = <VoiceLine>[
  VoiceLine('voice_still_up', 'still up?'),
  VoiceLine('voice_found_it', 'I found it.'),
  VoiceLine('voice_here', "Someone's here."),
  VoiceLine('voice_sam', "If you're hearing this, Sam."),
  VoiceLine('voice_stop', 'Stop looking.'),
  VoiceLine('voice_alive', "She's alive if you stop."),
  VoiceLine('voice_marina', 'Stay away from the marina.'),
  VoiceLine('voice_quiet', "Don't tell anyone."),
];

final spokenVoiceIds = {for (final v in spokenVoices) v.id};

VoiceLine? spokenVoice(String id) {
  for (final v in spokenVoices) {
    if (v.id == id) return v;
  }
  return null;
}
