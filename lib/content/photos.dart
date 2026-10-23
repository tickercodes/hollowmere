/// Photo registry: everything that can appear in Wren's Library, in chat
/// bubbles, on the case board, or as a scene backdrop.
class Hotspot {
  const Hotspot({
    required this.id,
    required this.dx,
    required this.dy,
    required this.label,
    required this.detail,
    this.radius = 0.09,
  });

  final String id;

  /// Normalised 0..1 position in the image.
  final double dx;
  final double dy;
  final String label;
  final String detail;

  /// Tap radius in normalised image units. Larger for a carving that spans the trunk.
  final double radius;
}

class Photo {
  const Photo({
    required this.id,
    required this.asset,
    required this.caption,
    required this.meta,
    this.hotspots = const [],
    this.aspect = 3 / 4,
  });

  final String id;
  final String asset;
  final String caption;

  /// Fake EXIF line shown under the photo ("Tue 11:52 PM · Marina Rd").
  final String meta;
  final List<Hotspot> hotspots;
  final double aspect;
}

const _e = 'assets/img/evidence';
const _l = 'assets/img/locations';
const _k = 'assets/img/key';

const photos = <String, Photo>{
  'sams_street': Photo(
    id: 'sams_street',
    asset: '$_e/ev_sams_street.jpg',
    caption: 'Ferry Street',
    meta: 'Last night 1:12 AM · a few houses from your door',
  ),
  'dock_night': Photo(
    id: 'dock_night',
    asset: '$_e/ev_dock_night.jpg',
    caption: 'Marina, north dock',
    meta: 'Tue 11:31 PM · Marina Rd',
    hotspots: [
      Hotspot(id: 'locker', dx: 0.17, dy: 0.29, label: 'Locker 14',
          detail: 'A locker with a new padlock. Number 14.'),
      Hotspot(id: 'siren', dx: 0.69, dy: 0.28, label: 'Spillway siren',
          detail: 'The red warning light on the spillway house is on. It should only be on before they open the gates.'),
      Hotspot(id: 'badge', dx: 0.9, dy: 0.84, label: 'Car reflection',
          detail: 'Headlights and a chrome badge in the puddle. A dark, expensive car. Not Jonah\'s truck.'),
    ],
  ),
  'birthday_cake': Photo(
    id: 'birthday_cake',
    asset: '$_e/ev_birthday_cake.jpg',
    caption: 'nineteen!!',
    meta: '3 weeks ago · The Waterline',
    hotspots: [
      Hotspot(id: 'candles', dx: 0.45, dy: 0.45, label: 'Candles',
          detail: 'Two number candles: 1 and 9.'),
      Hotspot(id: 'napkin', dx: 0.8, dy: 0.82, label: 'Napkin',
          detail: 'A heart drawn in pen. Someone was flirting.'),
    ],
  ),
  'caleb_notebook': Photo(
    id: 'caleb_notebook',
    asset: '$_e/ev_caleb_notebook.jpg',
    caption: 'locker 14',
    meta: 'Wed 12:02 AM · Marina Rd',
    hotspots: [
      Hotspot(id: 'polaroid', dx: 0.36, dy: 0.32, label: 'Polaroid',
          detail: 'The spillway house, photographed in daylight, years ago.'),
      Hotspot(id: 'grids', dx: 0.6, dy: 0.65, label: 'Grids',
          detail: 'Pages of hand-drawn 9x9 grids. Some cells are shaded on purpose.'),
    ],
  ),
  'relay_field': Photo(
    id: 'relay_field',
    asset: '$_e/ev_drowned_orchard.jpg',
    caption: 'hollowmere below - 07',
    meta: '2 weeks ago · Reservoir, east basin',
    aspect: 16 / 9,
    hotspots: [
      Hotspot(id: 'code', dx: 0.18, dy: 0.48, radius: 0.16, label: '1986',
          detail: '1-9-8-6 scratched into the near trunk. The year the church went under.'),
    ],
  ),
  'gauge_spire': Photo(
    id: 'gauge_spire',
    asset: '$_e/ev_underwater_sign.jpg',
    caption: 'hollowmere below - 12',
    meta: '2 weeks ago · 6 m depth',
  ),
  'inspection_report': Photo(
    id: 'inspection_report',
    asset: '$_e/ev_inspection_report.jpg',
    caption: 'IMG_4471',
    meta: 'Wed 12:58 AM · Town Hall',
    hotspots: [
      Hotspot(id: 'stamp', dx: 0.5, dy: 0.47, label: 'FAIL',
          detail: 'The real 2006 result. FAIL: seepage under the spillway wall. The filed copy says PASS.'),
      Hotspot(id: 'signature', dx: 0.42, dy: 0.8, label: 'Signature',
          detail: 'Signed by the inspector, J. M. Harlan. He died in 2007.'),
      Hotspot(id: 'year', dx: 0.36, dy: 0.21, radius: 0.12, label: 'Founded 1892',
          detail: 'Town seal, top left. Hollowmere, 1892.'),
    ],
  ),
  'spillway_2006': Photo(
    id: 'spillway_2006',
    asset: '$_e/ev_2006_spillway_photo.jpg',
    caption: 'scan_0018',
    meta: "Deacon's photo · 18 Nov 2006",
    aspect: 4 / 3,
    hotspots: [
      Hotspot(id: 'car', dx: 0.42, dy: 0.57, label: 'Car',
          detail: 'A dark car with council plates. Same badge shape as the puddle reflection.'),
      Hotspot(id: 'figure', dx: 0.6, dy: 0.54, label: 'Figure',
          detail: 'Someone in a long coat in the spillway house doorway.'),
      Hotspot(id: 'date', dx: 0.87, dy: 0.92, label: 'Date stamp',
          detail: "18 November 2006. The night Caleb Voss was last seen."),
    ],
  ),
  'diner_rota': Photo(
    id: 'diner_rota',
    asset: '$_e/ev_diner_rota.jpg',
    caption: 'IMG_4488',
    meta: 'Yesterday 11:40 PM · The Waterline',
    aspect: 4 / 3,
    hotspots: [
      Hotspot(id: 'swap', dx: 0.47, dy: 0.52, label: 'Thursday PM',
          detail: 'A name crossed out. "D.M." written over it. Deacon put himself on the Thursday night shift.'),
      Hotspot(id: 'window', dx: 0.84, dy: 0.55, label: 'Window',
          detail: 'The kitchen window faces the spillway. You can see the red siren light from here.'),
    ],
  ),
  'buoy_shed': Photo(
    id: 'buoy_shed',
    asset: '$_e/ev_buoy_shed.jpg',
    caption: 'the bell',
    meta: 'Now · Spillway boom shed',
  ),
  'missing_board': Photo(
    id: 'missing_board',
    asset: '$_e/ev_missing_board.jpg',
    caption: 'gas station board',
    meta: 'Epilogue',
  ),
  // Locations (used by scenes and the board).
  'loc_marina': Photo(id: 'loc_marina', asset: '$_l/loc_marina.jpg',
      caption: 'The marina', meta: '', aspect: 16 / 9),
  'loc_spillway': Photo(id: 'loc_spillway', asset: '$_l/loc_spillway_house.jpg',
      caption: 'Spillway house', meta: '', aspect: 16 / 9),
  'loc_diner': Photo(id: 'loc_diner', asset: '$_l/loc_waterline_diner.jpg',
      caption: 'The Waterline', meta: '', aspect: 16 / 9),
  'underwater_church': Photo(
    id: 'underwater_church',
    asset: '$_e/ev_underwater_church.jpg',
    caption: 'The drowned church',
    meta: 'Unknown · reservoir',
  ),
  'server_farm': Photo(
    id: 'server_farm',
    asset: '$_e/ev_server_farm.jpg',
    caption: 'The Core',
    meta: 'Tonight · below the mines',
  ),
  'loc_archive': Photo(id: 'loc_archive', asset: '$_l/loc_town_hall_archive.jpg',
      caption: 'Town hall archive', meta: '', aspect: 16 / 9),
  'key_art': Photo(id: 'key_art', asset: '$_k/key_art.jpg',
      caption: '', meta: '', aspect: 9 / 16),
  'kitchen_night': Photo(
    id: 'kitchen_night',
    asset: '$_l/loc_waterline_diner.jpg',
    caption: 'your kitchen',
    meta: 'Wed 11:53 PM · Ferry Street',
    aspect: 16 / 9,
    hotspots: [
      Hotspot(id: 'mug', dx: 0.32, dy: 0.62, label: 'Your mug',
          detail: 'Still on the counter. She was in the room.'),
      Hotspot(id: 'clock', dx: 0.55, dy: 0.28, label: 'Stove clock',
          detail: '11:53. Five minutes after you left the door open.'),
      Hotspot(id: 'car', dx: 0.78, dy: 0.48, label: 'Window',
          detail: 'In the glass: a car on Ferry Street. Lights off.'),
    ],
  ),
  'bait_dock': Photo(
    id: 'bait_dock',
    asset: '$_e/ev_dock_night.jpg',
    caption: 'north dock · 8:05 PM',
    meta: 'Tonight 8:05 PM · Marina Rd',
    hotspots: [
      Hotspot(id: 'car', dx: 0.9, dy: 0.84, label: 'Council car',
          detail: 'Engine off. Lights off. Nobody was told about this place except the mirror.'),
    ],
  ),
};

Photo photoOf(String id) {
  const aliases = {
    'ev_drowned_orchard': 'relay_field',
    'ev_inspection_report': 'inspection_report',
    'ev_underwater_church': 'underwater_church',
    'ev_server_farm': 'server_farm',
    'loc_town_hall_archive': 'loc_archive',
    'loc_server_farm': 'server_farm',
  };
  final p = photos[aliases[id] ?? id];
  if (p == null) throw ArgumentError('Unknown photo "$id"');
  return p;
}

const wallpaperSam = '$_k/wallpaper_sam.jpg';
const wallpaperWren = '$_k/wallpaper_wren.jpg';
