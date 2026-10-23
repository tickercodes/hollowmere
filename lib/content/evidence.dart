/// Evidence items and case-board pins. Evidence ids are granted by scripts;
/// the ending resolver counts them (bible §9).
class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.title,
    required this.summary,
    this.photo,
    this.episode = 1,
  });

  final String id;
  final String title;
  final String summary;
  final String? photo;
  final int episode;
}

const evidenceCatalog = <String, EvidenceItem>{
  'ev_unread': EvidenceItem(
    id: 'ev_unread',
    title: 'Your unread message',
    summary: '"come by, I\'ll leave the door open" - sent 11:47 PM on the 13th, never read.',
  ),
  'ev_street_photo': EvidenceItem(
    id: 'ev_street_photo',
    title: 'Photo of Ferry Street',
    summary: 'Taken from outside your house at 1:12 AM last night. Someone was there.',
    photo: 'sams_street',
  ),
  'ev_dock_photo': EvidenceItem(
    id: 'ev_dock_photo',
    title: 'Dock photo details',
    summary: 'Locker 14, the spillway siren on, and a dark car\'s badge in a puddle.',
    photo: 'dock_night',
  ),
  'ev_call_47s': EvidenceItem(
    id: 'ev_call_47s',
    title: '47-second call to "J."',
    summary: 'Her only outgoing call the night she vanished.',
  ),
  'ev_voicemail_tags': EvidenceItem(
    id: 'ev_voicemail_tags',
    title: 'Voicemail background',
    summary: 'Water, a two-tone siren already on, a bell at 0:31. She was near the spillway when the gates opened.',
  ),
  'ev_j_thread': EvidenceItem(
    id: 'ev_j_thread',
    title: 'One-sided thread with J.',
    summary: '"I\'m not going to tell them, just leave me alone." He never wrote back.',
  ),
  'ev_locker_note': EvidenceItem(
    id: 'ev_locker_note',
    title: 'Coded note to Tess',
    summary: 'Decoded: LOCKER 14 IF I GO QUIET.',
    episode: 2,
  ),
  'ev_notebook': EvidenceItem(
    id: 'ev_notebook',
    title: "Caleb's notebook",
    summary: 'Hand-drawn grids from 2006. Shaded cells hold numbers.',
    photo: 'caleb_notebook',
    episode: 2,
  ),
  'ev_pairing': EvidenceItem(
    id: 'ev_pairing',
    title: 'How her phone linked to yours',
    summary: 'Linked to JOHN-COTTAGE-WIFI, eleven days ago, 11:52 PM. She came by.',
    episode: 2,
  ),
  'ev_deleted_post': EvidenceItem(
    id: 'ev_deleted_post',
    title: 'Deleted post',
    summary: 'Old caption: "he\'s down there. they all knew."',
    photo: 'relay_field',
    episode: 3,
  ),
  'ev_rota': EvidenceItem(
    id: 'ev_rota',
    title: 'Shift rota swap',
    summary: 'Deacon put himself on the Thursday night shift. The kitchen window faces the spillway.',
    photo: 'diner_rota',
    episode: 3,
  ),
  'ev_report': EvidenceItem(
    id: 'ev_report',
    title: '2006 inspection report (original)',
    summary: 'FAIL. The filed copy says PASS. Signed by an inspector who died in 2007.',
    photo: 'inspection_report',
    episode: 3,
  ),
  'ev_timeline': EvidenceItem(
    id: 'ev_timeline',
    title: 'The night of the 11th, in order',
    summary: 'Five voicemails in order. Ardis called after the siren, not before.',
    episode: 4,
  ),
  'ev_live_wren': EvidenceItem(
    id: 'ev_live_wren',
    title: 'Live messages from Wren',
    summary: 'She is alive. "where the bell is."',
    episode: 4,
  ),
  'ev_sensor_log': EvidenceItem(
    id: 'ev_sensor_log',
    title: 'Sensor vs. official log',
    summary: "Jonah's sensor shows water drops the Authority log hides - on the 11th, the 13th, and in 2006.",
    episode: 5,
  ),
  'ev_2006_photo': EvidenceItem(
    id: 'ev_2006_photo',
    title: "Deacon's 2006 photo",
    summary: 'A council car at the spillway house, 18 Nov 2006.',
    photo: 'spillway_2006',
    episode: 5,
  ),
  'ev_voice_match': EvidenceItem(
    id: 'ev_voice_match',
    title: 'Her tell',
    summary: 'Ardis quoted the 47-second voicemail. Only you have heard it.',
    episode: 6,
  ),
  'ev_jonah_confession': EvidenceItem(
    id: 'ev_jonah_confession',
    title: "Jonah's account",
    summary: 'He gave Wren the notebook. He asked her to stop. He has the sensor.',
    episode: 4,
  ),
  'ev_mara_secret': EvidenceItem(
    id: 'ev_mara_secret',
    title: "Mara's admission",
    summary: 'She told Ardis about Wren\'s project. She gave Ardis their shared-plan login. She files the 2006 minutes and never spoke.',
    episode: 4,
  ),
  'ev_kitchen_photo': EvidenceItem(
    id: 'ev_kitchen_photo',
    title: 'Your kitchen, 11:53 PM',
    summary: 'Her photo from inside your house. In the window: a car on Ferry Street, lights off.',
    photo: 'kitchen_night',
    episode: 2,
  ),
  'ev_second_viewer': EvidenceItem(
    id: 'ev_second_viewer',
    title: 'Second viewer',
    summary: 'M. ELLISON on RESERVOIR-AUTH-STAFF. The shared backup has another reader.',
    episode: 3,
  ),
  'ev_bell_legend': EvidenceItem(
    id: 'ev_bell_legend',
    title: 'The bell is a log',
    summary: 'The fog-night bell rings only when the boom cable jerks. Every "ghost" was a night release.',
    episode: 3,
  ),
  'ev_bait_car': EvidenceItem(
    id: 'ev_bait_car',
    title: 'Council car at the north dock',
    summary: '8:05 PM. Nobody was told about the north dock except the mirror.',
    photo: 'bait_dock',
    episode: 5,
  ),
  'ev_harlan_2007': EvidenceItem(
    id: 'ev_harlan_2007',
    title: 'Sensor, 3 February 2007',
    summary: 'A fourth drop the night inspector Harlan "fell" from the spillway walkway.',
    episode: 4,
  ),
  'ev_spillway_log': EvidenceItem(
    id: 'ev_spillway_log',
    title: 'Spillway house log',
    summary: 'Blueprints and a detonation sequence hidden in the spillway office.',
    photo: 'loc_spillway',
    episode: 9,
  ),
};

/// A pin on the case board: a suspect (portrait) or a clue (note card).
class BoardPin {
  const BoardPin({
    required this.id,
    required this.label,
    this.character,
    this.note,
  });

  final String id;
  final String label;
  final String? character;
  final String? note;
  bool get isSuspect => character != null;
}

const boardPins = <String, BoardPin>{
  'wren': BoardPin(id: 'wren', label: 'WREN', character: 'wren'),
  'jonah': BoardPin(id: 'jonah', label: 'J. / JONAH', character: 'jonah'),
  'ardis': BoardPin(id: 'ardis', label: 'A. LOCKE', character: 'ardis'),
  'deacon': BoardPin(id: 'deacon', label: 'D. MOSS', character: 'deacon'),
  'tess': BoardPin(id: 'tess', label: 'TESS', character: 'tess'),
  'mara': BoardPin(id: 'mara', label: 'MARA E.', character: 'mara'),
  'caleb': BoardPin(id: 'caleb', label: 'CALEB 2006', character: 'caleb'),
  'warden': BoardPin(id: 'warden', label: 'THE WARDEN', character: 'warden'),
  'c_locker': BoardPin(id: 'c_locker', label: 'locker 14', note: 'New padlock. Notebook inside.'),
  'c_call': BoardPin(id: 'c_call', label: '47 sec call', note: 'Siren already on. Bell at 0:31 - gates opening.'),
  'c_bell': BoardPin(id: 'c_bell', label: 'the bell', note: 'Not the orchard relays. Rings when the boom cable jerks.'),
  'c_siren': BoardPin(id: 'c_siren', label: 'siren', note: 'Sounds ~30s before the gates open. Log says they did not.'),
  'c_report': BoardPin(id: 'c_report', label: 'FAIL report', note: 'The real 2006 check. The filed copy says PASS.'),
  'c_log': BoardPin(id: 'c_log', label: 'release log', note: 'Ardis sent it. The sensor does not match.'),
  'c_sedan': BoardPin(id: 'c_sedan', label: 'council car', note: 'In the puddle. In the 2006 photo.'),
  'c_rota': BoardPin(id: 'c_rota', label: 'rota swap', note: 'Deacon on Thursday nights. Window faces spillway.'),
  'c_pairing': BoardPin(id: 'c_pairing', label: 'linked 11:52', note: 'JOHN-COTTAGE-WIFI. She came inside.'),
  'c_relays': BoardPin(id: 'c_relays', label: 'frost relays', note: '"he\'s down there." 38 of 41 orchard relays salvaged.'),
  'roy': BoardPin(id: 'roy', label: 'R. TARRANT', character: 'roy'),
  'mayor_tape': BoardPin(id: 'mayor_tape', label: 'MAYOR TAPE', note: 'Corrupted recording. Someone kept downloading the town map.'),
  'payroll': BoardPin(id: 'payroll', label: 'PAYROLL', note: 'Jonah on Ardis\'s books.'),
  'mara_informant': BoardPin(id: 'mara_informant', label: 'INFORMANT', note: 'Mara started the day Wren began investigating.'),
  'unknown_number': BoardPin(id: 'unknown_number', label: 'UNKNOWN', note: 'A number that should not have this phone.'),
};
