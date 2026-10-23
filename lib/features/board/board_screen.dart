import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/characters.dart';
import '../../content/evidence.dart';
import '../../core/glass.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets.dart';

/// Fixed positions (normalised) so the board reads like the concept art:
/// Wren centre, suspects around her, clue cards in the gaps.
const _layout = <String, Offset>{
  'wren': Offset(0.5, 0.42),
  'jonah': Offset(0.16, 0.16),
  'ardis': Offset(0.84, 0.16),
  'deacon': Offset(0.14, 0.50),
  'tess': Offset(0.26, 0.82),
  'caleb': Offset(0.76, 0.80),
  'mara': Offset(0.86, 0.48),
  'warden': Offset(0.50, 0.90),
  'roy': Offset(0.50, 0.22),
  'c_locker': Offset(0.42, 0.10),
  'c_call': Offset(0.66, 0.36),
  'c_bell': Offset(0.62, 0.60),
  'c_siren': Offset(0.35, 0.30),
  'c_report': Offset(0.50, 0.70),
  'c_log': Offset(0.86, 0.66),
  'c_sedan': Offset(0.68, 0.12),
  'c_rota': Offset(0.14, 0.34),
  'c_pairing': Offset(0.34, 0.58),
  'c_relays': Offset(0.80, 0.94),
};

Offset positionOf(String id) {
  final p = _layout[id];
  if (p != null) return p;
  final r = math.Random(id.hashCode);
  return Offset(0.15 + r.nextDouble() * 0.7, 0.15 + r.nextDouble() * 0.7);
}

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});
  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  bool _connectMode = false;
  String? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(storyEngineProvider.notifier).report({'app': 'board'}));
  }

  void _tapPin(String id) {
    final engine = ref.read(storyEngineProvider.notifier);
    if (!_connectMode) {
      _showPin(id);
      return;
    }
    if (_pending == null) {
      setState(() => _pending = id);
      return;
    }
    if (_pending != id) {
      engine.toggleLink(_pending!, id);
      engine.report({'app': 'board', 'link': GameState.linkKey(_pending!, id)});
    }
    setState(() => _pending = null);
  }

  void _showPin(String id) {
    final pin = boardPins[id];
    if (pin == null) return;
    final game = ref.read(storyEngineProvider).game;
    final related = evidenceCatalog.values
        .where((e) => game.evidence.contains(e.id) && _relates(e, pin))
        .toList();
    showGlassSheet(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (pin.character != null) Avatar(pin.character!, size: 48, revealed: true),
                if (pin.character != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(c.tr(pin.label), style: displayStyle.copyWith(fontSize: 20)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pin.character != null)
              Text(c.tr(characterOf(pin.character!).subtitle),
                  style: const TextStyle(color: HmColors.textDim)),
            if (pin.note != null) Text(c.tr(pin.note!), style: const TextStyle(height: 1.5)),
            if (related.isNotEmpty) ...[
              const SizedBox(height: 14),
              const SectionLabel('Evidence on file'),
              for (final e in related)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${c.tr(e.title)}', style: const TextStyle(fontSize: 14)),
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _relates(EvidenceItem e, BoardPin pin) {
    final hay = '${e.title} ${e.summary}'.toLowerCase();
    final needle = (pin.character ?? pin.label).toLowerCase().split(RegExp(r'[ /.]')).where((s) => s.length > 2);
    return needle.any(hay.contains);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(storyEngineProvider.select((s) => s.game));
    return AppScaffold(
      title: 'Case Board',
      subtitle: context.fmt('{pins} pins · {links} connections', {
        'pins': game.boardPins.length,
        'links': game.boardLinks.length,
      }),
      actions: [
        IconButton(
          tooltip: context.tr('Evidence'),
          icon: const Icon(Icons.folder_special_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/evidence'),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: game.boardPins.isEmpty
                ? const EmptyHint('Pin something to the board to begin.', icon: Icons.push_pin_outlined)
                : BoardCanvas(
                    pins: game.boardPins,
                    links: game.boardLinks,
                    pending: _pending,
                    onTapPin: _tapPin,
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
                color: HmColors.surface, border: Border(top: BorderSide(color: HmColors.hairline))),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _connectMode ? HmColors.amber : HmColors.teal,
                      ),
                      onPressed: () => setState(() {
                        _connectMode = !_connectMode;
                        _pending = null;
                      }),
                      icon: Icon(_connectMode ? Icons.close_rounded : Icons.link_rounded),
                      label: Text(_connectMode
                          ? context.tr(_pending == null ? 'Pick first pin' : 'Pick second pin')
                          : context.tr('Connect')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/evidence'),
                      icon: const Icon(Icons.folder_special_rounded),
                      label: Text(context.fmt('Evidence · {n}', {'n': game.evidenceCount})),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The corkboard itself: pins at fixed positions, red string between links.
class BoardCanvas extends StatelessWidget {
  const BoardCanvas({
    super.key,
    required this.pins,
    required this.links,
    required this.onTapPin,
    this.pending,
    this.highlight = const {},
  });

  final Set<String> pins;
  final Set<String> links;
  final String? pending;
  final ValueChanged<String> onTapPin;

  /// Pin ids to draw with a teal glow (e.g. an accusation).
  final Set<String> highlight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          Offset center(String id) {
            final p = positionOf(id);
            return Offset(p.dx * size.width, p.dy * size.height);
          }
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1B1E21), Color(0xFF0D0F11)],
                radius: 1.1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StringPainter(
                      segments: [
                        for (final l in links)
                          if (pins.containsAll(l.split('|')))
                            (center(l.split('|')[0]), center(l.split('|')[1])),
                      ],
                    ),
                  ),
                ),
                for (final id in pins)
                  if (boardPins[id] != null)
                    _PositionedPin(
                      pin: boardPins[id]!,
                      center: center(id),
                      selected: pending == id,
                      glow: highlight.contains(id),
                      onTap: () => onTapPin(id),
                    ),
              ],
            ),
          );
        },
      );
}

class _PositionedPin extends StatelessWidget {
  const _PositionedPin({
    required this.pin,
    required this.center,
    required this.selected,
    required this.glow,
    required this.onTap,
  });
  final BoardPin pin;
  final Offset center;
  final bool selected;
  final bool glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = pin.isSuspect ? 82.0 : 84.0;
    final h = pin.isSuspect ? 104.0 : 54.0;
    final tilt = ((pin.id.hashCode % 7) - 3) * 0.02;
    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: tilt,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: pin.isSuspect ? const Color(0xFFEDE8DD) : const Color(0xFFD8C39A),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                if (selected || glow)
                  BoxShadow(
                      color: (selected ? HmColors.amber : HmColors.teal).withValues(alpha: 0.8),
                      blurRadius: 18),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                Column(
                  children: [
                    if (pin.isSuspect)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: HmColors.surfaceRaised,
                            image: characterOf(pin.character!).portrait == null
                                ? null
                                : DecorationImage(
                                    image: AssetImage(characterOf(pin.character!).portrait!),
                                    fit: BoxFit.cover,
                                    colorFilter: const ColorFilter.mode(Color(0x22000000), BlendMode.darken),
                                  ),
                          ),
                          alignment: Alignment.center,
                          child: characterOf(pin.character!).portrait == null
                              ? const Icon(Icons.person_off_outlined, color: HmColors.textDim)
                              : null,
                        ),
                      ),
                    if (!pin.isSuspect) const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        context.tr(pin.label),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HmColors.paperInk,
                          fontSize: pin.isSuspect ? 10 : 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Menlo',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (!pin.isSuspect) const Spacer(),
                  ],
                ),
                Positioned(
                  top: -2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? HmColors.amber : const Color(0xFFB8322E),
                        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StringPainter extends CustomPainter {
  _StringPainter({required this.segments});
  final List<(Offset, Offset)> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC62828)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final (a, b) in segments) {
      // A slight sag makes the string read as thread rather than a vector.
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + 12);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      canvas.drawPath(path.shift(const Offset(1, 2)), shadow);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StringPainter old) => old.segments.length != segments.length;
}
