/// Static cast data. Display names can be overridden per save (e.g. an
/// unknown number resolving to a real contact) via `GameState.contactNames`.
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.subtitle,
    this.portrait,
    this.defaultLabel,
  });

  final String id;
  final String name;
  final String subtitle;

  /// Asset path; null renders a monogram avatar.
  final String? portrait;

  /// How the contact appears before the player learns who they are.
  final String? defaultLabel;
}

const _p = 'assets/img/portraits';

const characters = <String, Character>{
  'wren': Character(
    id: 'wren',
    name: 'Wren',
    subtitle: 'last seen 11 days ago · still writing',
    portrait: '$_p/portrait_wren.jpg',
  ),
  'jonah': Character(
    id: 'jonah',
    name: 'Jonah Hale',
    subtitle: 'Dock mechanic',
    portrait: '$_p/portrait_jonah.jpg',
    defaultLabel: 'J.',
  ),
  'ardis': Character(
    id: 'ardis',
    name: 'Ardis Locke (Council)',
    subtitle: 'Runs the dam office',
    portrait: '$_p/portrait_ardis.jpg',
    defaultLabel: 'Unknown number',
  ),
  'deacon': Character(
    id: 'deacon',
    name: 'Deacon Moss',
    subtitle: 'The Waterline',
    portrait: '$_p/portrait_deacon.jpg',
  ),
  'tess': Character(
    id: 'tess',
    name: 'Tess Quinn',
    subtitle: "Wren's roommate",
    portrait: '$_p/portrait_tess.jpg',
  ),
  'mara': Character(
    id: 'mara',
    name: 'Mara Ellison',
    subtitle: "Wren's girlfriend · records clerk",
    portrait: '$_p/portrait_mara.jpg',
    defaultLabel: 'Unknown number',
  ),
  'caleb': Character(
    id: 'caleb',
    name: 'Caleb Voss',
    subtitle: 'Missing since 2006',
    portrait: '$_p/portrait_caleb.jpg',
  ),
  // Wren's one-sided thread with "J.", mirrored from her phone.
  'j_mirror': Character(
    id: 'j_mirror',
    name: "J. - from Wren's phone",
    subtitle: 'her texts only · no replies',
    portrait: '$_p/portrait_jonah.jpg',
    defaultLabel: "J. - from Wren's phone",
  ),
  'warden': Character(
    id: 'warden',
    name: 'THE WARDEN',
    subtitle: 'No caller ID',
  ),
  'news': Character(
    id: 'news',
    name: 'Hollowmere Courier',
    subtitle: 'News alerts',
  ),
  'roy': Character(
    id: 'roy',
    name: 'Roy Tarrant',
    subtitle: 'Reed Hydro · site security',
    defaultLabel: 'Unknown number',
  ),
  'player': Character(id: 'player', name: 'You', subtitle: ''),
};

Character characterOf(String id) =>
    characters[id] ?? Character(id: id, name: id, subtitle: '');
