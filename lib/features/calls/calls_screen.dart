import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import '../../content/voicemails.dart';
import '../../core/audio.dart';
import '../../core/theme.dart';
import '../../engine/game_state.dart';
import '../../engine/story_engine.dart';
import '../shell/widgets.dart';

/// Mirrored call log with an inline voicemail player.
class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key, this.initialVoicemail});
  final String? initialVoicemail;

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  String? _playing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEngineProvider.notifier).report({'app': 'calls'});
      if (widget.initialVoicemail != null) _open(widget.initialVoicemail!);
    });
  }

  void _open(String voicemailId) {
    setState(() => _playing = voicemailId);
    final engine = ref.read(storyEngineProvider.notifier);
    final entry = engine.game.callLog
        .where((c) => c.voicemail == voicemailId)
        .firstOrNull;
    if (entry != null && !engine.game.has('heard_${entry.id}')) {
      engine.applyEffects({'flags': ['heard_${entry.id}']});
    }
    engine.report({'app': 'calls', 'voicemail': voicemailId});
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(storyEngineProvider.select((s) => s.game.callLog));
    final entries = log.reversed.toList();
    return AppScaffold(
      title: 'Calls',
      subtitle: "Wren's phone · mirrored",
      body: entries.isEmpty
          ? const EmptyHint('Call history has not synced yet.')
          : ListView(
              children: [
                if (_playing != null)
                  VoicemailPlayer(
                    key: ValueKey(_playing),
                    voicemailId: _playing!,
                    onClose: () => setState(() => _playing = null),
                  ),
                for (final e in entries) _CallTile(entry: e, onVoicemail: _open),
              ],
            ),
    );
  }
}

class _CallTile extends ConsumerWidget {
  const _CallTile({required this.entry, required this.onVoicemail});
  final CallEntry entry;
  final ValueChanged<String> onVoicemail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heard = ref.watch(
        storyEngineProvider.select((s) => s.game.has('heard_${entry.id}')));
    final (icon, color) = switch (entry.direction) {
      'out' => (Icons.call_made_rounded, HmColors.teal),
      'missed' => (Icons.call_missed_rounded, HmColors.danger),
      _ => (Icons.call_received_rounded, HmColors.ok),
    };
    final d = entry.durationSeconds;
    final duration = d == null
        ? (entry.direction == 'missed' ? 'Missed' : '')
        : '${d ~/ 60}:${(d % 60).toString().padLeft(2, '0')}';
    return ListTile(
      leading: Avatar(entry.contact, size: 44),
      title: Text(displayName(ref, entry.contact)),
      subtitle: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('${entry.label}${duration.isEmpty ? '' : ' · $duration'}',
              style: const TextStyle(color: HmColors.textDim, fontSize: 12)),
        ],
      ),
      trailing: entry.voicemail == null
          ? null
          : IconButton(
              icon: Icon(Icons.voicemail_rounded,
                  color: heard ? HmColors.textDim : HmColors.amber),
              onPressed: () => onVoicemail(entry.voicemail!),
            ),
      onTap: entry.voicemail == null ? null : () => onVoicemail(entry.voicemail!),
    );
  }
}

/// Plays a voicemail asset with a seeded waveform and a scrolling transcript.
/// Exposes the current position via [onPosition] so forensics mini-games can
/// let the player tag what they hear.
class VoicemailPlayer extends ConsumerStatefulWidget {
  const VoicemailPlayer({
    super.key,
    required this.voicemailId,
    this.onClose,
    this.onPosition,
    this.markers = const [],
    this.compact = false,
    this.obscureCaller = false,
  });

  final String voicemailId;
  final VoidCallback? onClose;
  final ValueChanged<double>? onPosition;

  /// Seconds to draw as marks on the waveform (found cues).
  final List<double> markers;
  final bool compact;

  /// Hide who left it (Voice Match puzzle).
  final bool obscureCaller;

  @override
  ConsumerState<VoicemailPlayer> createState() => VoicemailPlayerState();
}

class VoicemailPlayerState extends ConsumerState<VoicemailPlayer> {
  Duration _pos = Duration.zero;
  Duration? _len;
  bool _playing = false;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  Timer? _fallback;
  final _stopwatch = Stopwatch();
  late final AudioService _audio;

  Voicemail get vm => voicemailOf(widget.voicemailId);

  double get seconds => _pos.inMilliseconds / 1000;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioProvider);
    _load();
  }

  Future<void> _load() async {
    final len = await _audio.loadVoicemail(widget.voicemailId);
    if (!mounted) return;
    setState(() => _len = len ?? Duration(seconds: vm.durationSeconds));
    if (len != null) {
      _posSub = _audio.voicemail.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _pos = p);
        widget.onPosition?.call(seconds);
      });
      _stateSub = _audio.voicemail.playerStateStream.listen((s) {
        if (!mounted) return;
        final done = s.processingState == ProcessingState.completed;
        setState(() => _playing = s.playing && !done);
      });
    }
  }

  Future<void> _toggle() async {
    final len = _len;
    if (len == null) return;
    // Several players can share the one voicemail channel (Voice Match);
    // make sure ours is the loaded clip before playing.
    if (_audio.currentVoicemail != widget.voicemailId) {
      await _audio.loadVoicemail(widget.voicemailId);
      if (!mounted) return;
    }
    final real = _audio.voicemail.duration != null;
    if (_playing) {
      if (real) {
        await _audio.voicemail.pause();
      } else {
        _fallback?.cancel();
        _stopwatch.stop();
      }
      setState(() => _playing = false);
      return;
    }
    if (_pos >= len) {
      await _seek(Duration.zero);
    }
    setState(() => _playing = true);
    if (real) {
      await _audio.voicemail.play();
    } else {
      // No audio device/asset: simulate playback so the transcript still runs.
      _stopwatch
        ..reset()
        ..start();
      final start = _pos;
      _fallback = Timer.periodic(const Duration(milliseconds: 120), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        final p = start + _stopwatch.elapsed;
        if (p >= len) {
          t.cancel();
          setState(() {
            _pos = len;
            _playing = false;
          });
          return;
        }
        setState(() => _pos = p);
        widget.onPosition?.call(seconds);
      });
    }
  }

  Future<void> _seek(Duration d) async {
    if (_audio.voicemail.duration != null) {
      await _audio.voicemail.seek(d);
    }
    if (!mounted) return;
    setState(() => _pos = d);
    widget.onPosition?.call(seconds);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _fallback?.cancel();
    unawaited(_audio.voicemail.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = _len ?? Duration(seconds: vm.durationSeconds);
    final progress = len.inMilliseconds == 0
        ? 0.0
        : (_pos.inMilliseconds / len.inMilliseconds).clamp(0.0, 1.0);
    final visibleTranscript = [
      for (final line in vm.transcript)
        if (_lineTime(line) <= seconds + 0.01 || _lineTime(line) < 0) line
    ];

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(14),
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.obscureCaller
                  ? const Avatar('warden', size: 34)
                  : Avatar(vm.from, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        widget.obscureCaller
                            ? 'Recording · unidentified'
                            : 'Voicemail · ${displayName(ref, vm.from)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(widget.obscureCaller ? 'background: ?' : vm.background,
                        style: monoStyle.copyWith(fontSize: 10, color: HmColors.textDim)),
                  ],
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: widget.onClose),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _scrub(d.localPosition.dx, context, len),
            onHorizontalDragUpdate: (d) => _scrub(d.localPosition.dx, context, len),
            child: SizedBox(
              height: widget.compact ? 44 : 64,
              width: double.infinity,
              child: CustomPaint(
                painter: WaveformPainter(
                  seed: widget.voicemailId.hashCode,
                  progress: progress,
                  markers: [for (final m in widget.markers) m / len.inSeconds],
                  cues: [for (final c in vm.cues) c.at / len.inSeconds],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton.filled(
                onPressed: _toggle,
                icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
              const SizedBox(width: 8),
              Text('${_fmt(_pos)} / ${_fmt(len)}', style: monoStyle),
              const Spacer(),
              IconButton(
                tooltip: 'Back 5s',
                onPressed: () => _seek(
                    Duration(seconds: math.max(0, _pos.inSeconds - 5))),
                icon: const Icon(Icons.replay_5_rounded),
              ),
            ],
          ),
          if (!widget.compact) ...[
            const Divider(height: 18),
            for (final line in visibleTranscript)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line,
                    style: monoStyle.copyWith(
                        color: line.contains('(') ? HmColors.amber : HmColors.text)),
              ),
            if (visibleTranscript.isEmpty)
              Text('press play', style: monoStyle.copyWith(color: HmColors.textDim)),
          ],
        ],
      ),
    );
  }

  void _scrub(double dx, BuildContext context, Duration len) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final width = box.size.width - 28; // card padding
    final f = (dx / width).clamp(0.0, 1.0);
    _seek(Duration(milliseconds: (len.inMilliseconds * f).round()));
  }

  static double _lineTime(String line) {
    final m = RegExp(r'^\[(\d+):(\d+)\]').firstMatch(line);
    if (m == null) return -1;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!).toDouble();
  }

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.seed,
    required this.progress,
    this.markers = const [],
    this.cues = const [],
  });

  final int seed;
  final double progress;
  final List<double> markers;
  final List<double> cues;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    const bars = 72;
    final w = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final f = i / bars;
      // Bumps near cue points so the ear and eye agree.
      var amp = 0.15 + r.nextDouble() * 0.45;
      for (final c in cues) {
        final d = (f - c).abs();
        if (d < 0.03) amp = math.max(amp, 0.95 - d * 10);
      }
      final h = size.height * amp;
      final paint = Paint()
        ..color = f <= progress ? HmColors.teal : HmColors.tealDim
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.55;
      final x = i * w + w / 2;
      canvas.drawLine(
          Offset(x, size.height / 2 - h / 2), Offset(x, size.height / 2 + h / 2), paint);
    }
    for (final m in markers) {
      final x = m * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          Paint()..color = HmColors.amber..strokeWidth = 2);
      canvas.drawCircle(Offset(x, 4), 4, Paint()..color = HmColors.amber);
    }
    final px = progress * size.width;
    canvas.drawLine(Offset(px, 0), Offset(px, size.height),
        Paint()..color = HmColors.text.withValues(alpha: 0.8)..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter old) =>
      old.progress != progress || old.markers.length != markers.length;
}
