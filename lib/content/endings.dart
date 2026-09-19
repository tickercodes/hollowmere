class Ending {
  const Ending({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.paragraphs,
    required this.image,
    this.sting = const [],
    this.fullTrust = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> paragraphs;
  final String image;

  /// Always shown after the main paragraphs.
  final List<String> sting;

  /// Shown when Jonah, Tess, Deacon and Mara all trust you.
  final List<String> fullTrust;
}

const endings = <String, Ending>{
  'files': Ending(
    id: 'files',
    title: 'THE FILES',
    subtitle: 'Best ending',
    image: 'missing_board',
    paragraphs: [
      'Deacon Moss walked into the station at 6:40 AM with a photo in an envelope. He would not leave until Chief Whitlock listened to a 47-second voicemail.',
      'By noon the real 2006 report was on the state engineer\'s desk. Full Pool Day was cancelled. By evening, divers had marked three frost-relay posts that were never salvaged. Caleb Voss came home on the fourth day.',
      'Ardis Locke did not quit. She was arrested in the dam office car park, telling a reporter that the town looks after its own.',
      'Wren slept for fourteen hours at Mara\'s. When she woke she asked if you had left the door open. You had.',
      'At the gas station, the fourth flyer came down. The first three were replaced by one card with one name and one date. The board has been empty since.',
      'In November the orchard gauge-spire breaks the surface, and Wren shoots the first frame of a new series: Hollowmere Above.',
    ],
    fullTrust: [
      'At the hearing, Mara Ellison stands up and reads the login she gave away. It is short. It is the first sentence she has said out loud about what she did.',
    ],
    sting: [
      'Whitlock opens a new folder. The label reads Harlan, 2007.',
    ],
  ),
  'high_water': Ending(
    id: 'high_water',
    title: 'HIGH WATER',
    subtitle: 'Bittersweet ending',
    image: 'loc_spillway',
    paragraphs: [
      'They found Wren in the boom shed. She had no water, and a broken wrist from the night she ran. She would not say who she ran from until she saw you.',
      'Ardis Locke quit as chair "to step back from public life." The lawyer said the proof was not enough. Reed Hydro kept the contract.',
      'Full Pool Day happened, quieter. The state ordered a new check of the spillway. Results come next year.',
      'Jonah Hale still logs the water every minute. He says someone should.',
    ],
    sting: [
      '23:41. The siren sounds. Your phone lights up with a photo of your own front door, taken from across the road, and the caption: still up?',
    ],
  ),
  'radio_silence': Ending(
    id: 'radio_silence',
    title: 'RADIO SILENCE',
    subtitle: 'Tragic ending',
    image: 'loc_marina',
    paragraphs: [
      'The boom shed was empty when the police got there. A sleeping bag, a camera, and a phone with 3% battery.',
      'The messages from the last three days were sent by a timer. Wren wrote them the night she ran, to go out if she did not come back and stop them. She never stopped them.',
      'The 2006 report was real. Caleb Voss\'s case was opened again. Ardis Locke was asked questions and let go.',
      'Wren Calloway is still missing. Her flyer is the fourth face on the gas station board.',
      'Your last message to her is still unread. The counter on the lock screen keeps climbing.',
    ],
  ),
  'warden': Ending(
    id: 'warden',
    title: 'THE WARDEN',
    subtitle: 'You helped hide it',
    image: 'loc_diner',
    paragraphs: [
      'You did what the Warden asked. You stopped.',
      'Wren was "found" two days later, walking on the county road. The official story said she had been staying with a friend and needed time away. She did not fix the story. Neither did you.',
      'Deacon poured you a coffee and did not charge you. Neither of you talked about the photo.',
      'You deleted the Cloud Backup app. Her photos left your phone. Nothing has come through since.',
      'On foggy nights you can still hear the bell. Now you know exactly what it is counting.',
    ],
  ),
};

List<String> endingCopy(Ending ending, {required bool fullTrust}) => [
      ...ending.paragraphs,
      if (fullTrust) ...ending.fullTrust,
      ...ending.sting,
    ];
