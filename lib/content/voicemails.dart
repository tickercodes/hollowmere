/// Voicemail audio assets with transcripts and the background cues the
/// forensics mini-games reference. Times are seconds into the clip and match
/// tools/build_audio.py exactly.
class VoicemailCue {
  const VoicemailCue({required this.id, required this.at, required this.label, required this.detail});
  final String id;
  final double at;
  final String label;
  final String detail;
}

class Voicemail {
  const Voicemail({
    required this.id,
    required this.from,
    required this.durationSeconds,
    required this.transcript,
    this.cues = const [],
    this.background = '',
  });

  final String id;
  final String from;
  final int durationSeconds;
  final List<String> transcript;
  final List<VoicemailCue> cues;

  /// Short description of the ambient bed ("dock water", "diner hum").
  final String background;
}

const voicemails = <String, Voicemail>{
  'vm_wren_47s': Voicemail(
    id: 'vm_wren_47s',
    from: 'wren',
    durationSeconds: 47,
    background: 'open water, wind',
    transcript: [
      '[0:02] (two-tone siren, already sounding)',
      '[0:06] Jonah. Jonah, I found it. I found the box.',
      "[0:10] It's exactly where he said. The grids were right, all of them.",
      "[0:16] I'm at the- wait.",
      '[0:31] (a bell, single strike)',
      "[0:39] (whispered) Someone's here.",
      '[0:44] (car door)',
      '[0:46] (line cut)',
    ],
    cues: [
      VoicemailCue(id: 'water', at: 12.0, label: 'Water', detail: 'Open water close by, and wind. She is outside, on the shore or a dock.'),
      VoicemailCue(id: 'siren', at: 3.0, label: 'Two-tone siren', detail: 'Already sounding. The spillway warning. It starts about thirty seconds before the gates open.'),
      VoicemailCue(id: 'bell', at: 31.5, label: 'Bell', detail: 'One bell strike. The boom cable, when the gates open. Not the orchard frost relays.'),
      VoicemailCue(id: 'car_door', at: 44.0, label: 'Car door', detail: 'A heavy door, close. Someone arrived by car.'),
    ],
  ),
  'vm_jonah': Voicemail(
    id: 'vm_jonah',
    from: 'jonah',
    durationSeconds: 9,
    background: 'dock, water',
    transcript: ["It's Jonah. Whatever she told you, forget it. Stay away from the marina. I mean it. Please."],
  ),
  'vm_mara': Voicemail(
    id: 'vm_mara',
    from: 'mara',
    durationSeconds: 12,
    background: 'quiet room',
    transcript: ["John, it's Mara Ellison. Wren and I are together. The police won't tell me anything. If you've heard from her, anything at all, please call me back."],
  ),
  'vm_deacon': Voicemail(
    id: 'vm_deacon',
    from: 'deacon',
    durationSeconds: 11,
    background: 'kitchen hum, a bell near the end',
    transcript: ["It's Deacon, from the Waterline. Wren left her camera bag here. You should come get it. Come after close. Don't tell anyone."],
  ),
  'vm_ardis': Voicemail(
    id: 'vm_ardis',
    from: 'ardis',
    durationSeconds: 13,
    background: 'office hum',
    transcript: ["John, this is Ardis Locke. I wanted to check in myself. This town looks after its own. If the police have Wren's phone I'd like to know, so I can push them. Call me."],
  ),
  'vm_unknown': Voicemail(
    id: 'vm_unknown',
    from: 'warden',
    durationSeconds: 5,
    background: 'inside a car, engine off',
    transcript: ["Stop looking. She's alive if you stop."],
    cues: [
      VoicemailCue(id: 'siren', at: 0.6, label: 'Siren', detail: 'Spillway warning, faint through the car body.'),
      VoicemailCue(id: 'ringtone', at: 2.4, label: 'Ringtone', detail: 'A phone ringing on the passenger seat. Nobody answers.'),
      VoicemailCue(id: 'static', at: 4.2, label: 'Static', detail: 'The line dies in a burst of static.'),
    ],
  ),
  'vm_wren_memo1': Voicemail(
    id: 'vm_wren_memo1',
    from: 'wren',
    durationSeconds: 11,
    background: 'close, indoor',
    transcript: [
      "If you're hearing this - hi. I left this in case I go quiet.",
      "Don't be mad I used your wifi. You were the only person here who wasn't here in 2006.",
    ],
  ),
  'vm_wren_memo2': Voicemail(
    id: 'vm_wren_memo2',
    from: 'wren',
    durationSeconds: 9,
    background: 'wind, water',
    transcript: [
      "The bell isn't the orchard relays. It rings when they open the gates. That's the whole trick.",
      "Jonah has the numbers. Trust him even when he won't write anything down.",
    ],
  ),
  'vm_wren_memo3': Voicemail(
    id: 'vm_wren_memo3',
    from: 'wren',
    durationSeconds: 8,
    background: 'shed, close',
    transcript: [
      "If this is the last one: say her name. Out loud. Someone has to be first.",
      "And leave the door open. You always do.",
    ],
  ),
};

Voicemail voicemailOf(String id) {
  final v = voicemails[id];
  if (v == null) throw ArgumentError('Unknown voicemail "$id"');
  return v;
}
