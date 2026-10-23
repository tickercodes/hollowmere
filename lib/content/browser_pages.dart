import '../l10n/l10n.dart';

/// The in-game web. Pages are found by searching keywords or by following
/// links from other pages. `hidden` pages never appear in search until a
/// script grants them (e.g. a URL from a chat).
class WebPage {
  const WebPage({
    required this.id,
    required this.title,
    required this.url,
    required this.site,
    required this.keywords,
    required this.body,
    this.links = const [],
    this.image,
    this.hidden = false,
  });

  final String id;
  final String title;
  final String url;
  final String site;
  final List<String> keywords;

  /// Paragraphs. Lines starting with `# ` render as headings.
  final List<String> body;
  final List<String> links;
  final String? image;
  final bool hidden;

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return false;

    final pageUrl = url.toLowerCase();
    for (final candidate in browserQueryUrlCandidates(q)) {
      if (candidate == pageUrl ||
          pageUrl.contains(candidate) ||
          candidate.contains(pageUrl)) {
        return true;
      }
    }

    final terms = q.split(RegExp(r'\s+'));
    final hay = [
      url,
      title,
      L10nCatalog.lookup(title),
      site,
      L10nCatalog.lookup(site),
      ...keywords,
      ...keywords.map(L10nCatalog.lookup),
      ...body,
      ...body.map(L10nCatalog.lookup),
    ].join(' ').toLowerCase();
    return terms.every(hay.contains);
  }
}

/// Normalizes pasted chat links and typed URLs for comparison with [WebPage.url].
Iterable<String> browserQueryUrlCandidates(String query) sync* {
  var q = query.toLowerCase().trim();
  if (q.isEmpty) return;

  String strip(String s) {
    var out = s.trim();
    for (final prefix in ['https://', 'http://', 'www.']) {
      if (out.startsWith(prefix)) out = out.substring(prefix.length);
    }
    while (out.isNotEmpty && (out.endsWith('/') || out.endsWith('.'))) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  yield strip(q);

  final urlLike = RegExp(
    r'(?:https?://)?(?:www\.)?([a-z0-9][\w.-]*(?:/[\w./-]*)?)',
    caseSensitive: false,
  );
  for (final m in urlLike.allMatches(q)) {
    final hit = strip(m.group(0)!);
    if (hit.isNotEmpty) yield hit;
    final hostPath = m.group(1);
    if (hostPath != null && hostPath.isNotEmpty) yield strip(hostPath);
  }

  // First token when someone pastes "url - rest of sentence" from chat.
  final first = q.split(RegExp(r'\s+')).first;
  if (first.contains('.') || first.contains('/')) yield strip(first);
}

const webPages = <String, WebPage>{
  'courier_missing': WebPage(
    id: 'courier_missing',
    title: 'Hollowmere PD confirms 19-year-old reported missing',
    url: 'hollowmerecourier.com/news/missing-woman',
    site: 'Hollowmere Courier',
    keywords: ['wren', 'calloway', 'missing', 'hollowmere', 'police', 'news'],
    body: [
      'HOLLOWMERE - Police confirmed on Tuesday that a 19-year-old woman has been reported missing. She did not come home eleven days ago.',
      'Chief Dana Whitlock would not name the woman or say more, citing "an active inquiry." People close to her named her as Wren Calloway, a barista at The Waterline and a photography student.',
      'Councilwoman Ardis Locke, who runs the Reservoir Authority, said the town "looks after its own" and asked anyone with information to come forward.',
      'The Courier understands officers searched the boarded-up marina on Marina Road on Monday.',
    ],
    links: ['courier_2006_runaway', 'authority_schedule'],
  ),
  'courier_2006_runaway': WebPage(
    id: 'courier_2006_runaway',
    title: 'Voss boy believed to have left town, say police (Nov 2006)',
    url: 'hollowmerecourier.com/archive/2006/voss',
    site: 'Hollowmere Courier · Archive',
    keywords: ['caleb', 'voss', '2006', 'runaway', 'boy', 'missing', 'archive'],
    body: [
      'HOLLOWMERE, 24 November 2006 - Police believe 17-year-old Caleb Voss, last seen on the evening of 18 November, left the area of his own choice.',
      '"There is no sign of a crime," said then-Chief Raymond Pell. "Caleb had spoken to friends about leaving Hollowmere."',
      'He vanished the same week the council voted 5–2 to finish the dam. The flood would cover the last of the old village, including the east basin orchard where he worked and its numbered frost-relay posts. Elias Quinn, who kept the orchard, spoke out against it louder than anyone. A dock mechanic, Jonah, reported him missing. Police listed the case as a runaway.',
      'Councilwoman Ardis Locke, who put the vote forward, said it was "hard, but needed, for the town\'s future."',
    ],
    links: ['historical_society', 'courier_vote'],
  ),
  'courier_vote': WebPage(
    id: 'courier_vote',
    title: 'Council approves final flood phase 5–2 (Nov 2006)',
    url: 'hollowmerecourier.com/archive/2006/vote',
    site: 'Hollowmere Courier · Archive',
    keywords: ['dam', 'expansion', 'vote', 'council', '2006', 'locke', 'reed'],
    body: [
      'The expansion contract, worth about 14 million, went to Reed Hydro. Developer Everett Reed called the inspection "clean" and said work would start within the month.',
      'The state inspection report, filed by engineer J. M. Harlan, graded the spillway and bank as PASS. Mr Harlan could not be reached.',
      'Councilwoman Locke ran the meeting. The two votes against came from Elias Quinn. One council seat was empty. The minutes do not name it.',
    ],
    links: ['harlan_obit'],
  ),
  'harlan_obit': WebPage(
    id: 'harlan_obit',
    title: 'Obituary: James M. Harlan, P.E., 1951–2007',
    url: 'stateengineering.org/obituaries/harlan',
    site: 'State Engineering Society',
    keywords: ['harlan', 'inspector', 'engineer', 'obituary', '2007'],
    body: [
      'James Harlan, an engineer for 31 years, died in March 2007 after a fall from the Hollowmere spillway walkway. He checked more than two hundred dams and spillways across the state.',
      'Friends remembered him as "careful to a fault." Colleagues asked that donations go to the spillway safety fund.',
      'Note: Mr Harlan\'s last signed inspection, for the Hollowmere expansion, was the subject of a 2008 records request. The request was refused.',
    ],
  ),
  'historical_society': WebPage(
    id: 'historical_society',
    title: 'Hollowmere Below - the drowned village',
    url: 'hollowmerehistory.org/below',
    site: 'Hollowmere Historical Society',
    keywords: ['hollowmere', 'below', 'drowned', 'village', 'old town', 'orchard', 'frost', 'relay', 'bell', 'flood', 'map'],
    body: [
      '# The old village',
      'When the dam went up in 1986 the village of Hollowmere moved to the ridge. In 2006 the expansion took the last of it: the east basin orchard, its frost-relay grid, and the river gauge-spire that still marks the old waterline.',
      '# The bell',
      'People say they hear a bell on foggy nights and think the drowned orchard is still calling pickers to light the smudge pots. It is not. The sound comes from an old warning buoy on the spillway boom. The Authority never took it away. A small shed on the shore still holds its original brass bell.',
      'A volunteer adds: the bell rings only when the boom cable jerks - when the gates open, and again when they close.',
      '# The frost relays',
      'Forty-one numbered brass frost-relay posts were meant to be salvaged before the 2006 flood. Each post rang a small bell when the temperature dropped, so pickers would wake and light the pots. Authority records show thirty-eight were pulled. The rest lie about 6 m under the water, 400 m east of the marina.',
    ],
    image: 'relay_field',
    links: ['authority_schedule'],
  ),
  'authority_schedule': WebPage(
    id: 'authority_schedule',
    title: 'Spillway release schedule & warning procedures',
    url: 'hollowmere-authority.gov/spillway',
    site: 'Hollowmere Reservoir Authority',
    keywords: ['spillway', 'release', 'schedule', 'siren', 'authority', 'warning', 'log'],
    body: [
      'Controlled releases take place on the published schedule only. A two-tone warning siren sounds for about thirty seconds before the gates open.',
      'Each release is written in the official Release Log, kept by the Authority chair\'s office and available on request.',
      'Chair: Councilwoman Ardis Locke. Day-to-day work: Reed Hydro.',
      'Published schedule this month: 06:00 and 18:00 daily. No night releases are planned.',
    ],
  ),
  'wren_portfolio': WebPage(
    id: 'wren_portfolio',
    title: 'wren.calloway - hollowmere below (work in progress)',
    url: 'wrencalloway.photo/below',
    site: 'Portfolio',
    keywords: ['wren', 'calloway', 'photo', 'portfolio', 'hollowmere below'],
    body: [
      'a town built on top of another town. i want to photograph what\'s underneath before they pretend it was never there.',
      '12 frames so far. more soon. if you know anyone who was here in 2006 and will talk to me - message me.',
    ],
    image: 'gauge_spire',
  ),
  'photo_underwater_howto': WebPage(
    id: 'photo_underwater_howto',
    title: 'How to photograph underwater on a budget',
    url: 'shutterdive.net/budget-housing',
    site: 'ShutterDive',
    keywords: ['underwater', 'photograph', 'housing', 'camera', 'budget'],
    body: [
      'A waterproof phone case and a dive light will get you to six metres. Shoot at dawn for the clearest water.',
    ],
  ),
  'reed_hydro': WebPage(
    id: 'reed_hydro',
    title: 'Reed Hydro - Infrastructure Partners',
    url: 'reedhydro.com',
    site: 'Reed Hydro',
    keywords: ['reed', 'hydro', 'everett', 'developer', 'contract', 'dam'],
    body: [
      'Reed Hydro has built water projects across the region since 1994. Founder and CEO Everett Reed.',
      'Current work: Hollowmere Dam Phase III (run and repair), awarded 2024.',
    ],
  ),
  'locker_rental': WebPage(
    id: 'locker_rental',
    title: 'Marina lockers - no longer maintained',
    url: 'hollowmere-authority.gov/marina',
    site: 'Hollowmere Reservoir Authority',
    keywords: ['marina', 'locker', 'lockers', 'dock'],
    body: [
      'The north dock lockers were closed in 2011. Keys were not taken back. The Authority is not responsible for items left in lockers.',
    ],
  ),
  'cache_wren_post': WebPage(
    id: 'cache_wren_post',
    title: 'Cached copy - wren.calloway post #7',
    url: 'webcache.archive/wrencalloway/7',
    site: 'Archive cache',
    keywords: ['cache', 'archive', 'wren', 'post'],
    hidden: true,
    body: [
      'This is a saved copy from 16 days ago. The live post has been edited since then.',
      'Caption (saved): "hollowmere below - 07. he\'s down there. they all knew."',
      'Caption (live): "38."',
    ],
    image: 'relay_field',
  ),
  'release_log_pdf': WebPage(
    id: 'release_log_pdf',
    title: 'Official Release Log - extract (supplied by A. Locke)',
    url: 'hollowmere-authority.gov/log/extract',
    site: 'Hollowmere Reservoir Authority',
    keywords: ['release', 'log', 'official', 'extract'],
    hidden: true,
    body: [
      'Release Log, extract for the 10th–13th.',
      '10th: 06:00 release (planned). 18:00 release (planned).',
      '11th: 06:00 release (planned). 18:00 release (planned). No night work.',
      '12th: 06:00 release (planned). 18:00 release (planned).',
      '13th: 06:00 release (planned). 18:00 release (planned). No night work.',
      'Signed as accurate - Office of the Chair.',
    ],
  ),
  'buoy_shed_map': WebPage(
    id: 'buoy_shed_map',
    title: 'Boom maintenance access - shore path',
    url: 'hollowmere-authority.gov/boom-access',
    site: 'Hollowmere Reservoir Authority',
    keywords: ['boom', 'buoy', 'shed', 'access', 'path'],
    hidden: true,
    body: [
      'To reach the boom shed, take the shore path from the spillway car park. Padlock code held by the Chair\'s office.',
    ],
  ),
};

List<WebPage> searchPages(String query, Set<String> discovered) => [
      for (final p in webPages.values)
        if ((!p.hidden || discovered.contains(p.id)) && p.matches(query)) p
    ];
