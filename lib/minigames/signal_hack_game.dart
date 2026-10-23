import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../core/theme.dart';
import '../engine/story_engine.dart';
import 'minigame_scaffold.dart';

class SignalHackGame extends ConsumerStatefulWidget {
  const SignalHackGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<SignalHackGame> createState() => _SignalHackGameState();
}

class _SignalHackGameState extends ConsumerState<SignalHackGame> with SingleTickerProviderStateMixin {
  double _freq = 90.0;
  double _amp = 50.0;
  late AnimationController _anim;

  double get targetFreq => (widget.interaction.node.config['target_freq'] as num).toDouble();
  double get targetAmp => (widget.interaction.node.config['target_amp'] as num).toDouble();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _check() {
    if ((_freq - targetFreq).abs() < 1.5 && (_amp - targetAmp).abs() < 5.0) {
      ref.minigameSuccess(context, message: 'Signal Matched.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.interaction.node.config;
    return MinigameScaffold(
      interaction: widget.interaction,
      brief: cfg['brief'] as String?,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: HmColors.teal, width: 2),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(_freq, _amp, targetFreq, targetAmp, _anim.value),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                const Text('FREQ', style: monoStyle),
                Expanded(
                  child: Slider(
                    value: _freq,
                    min: 80.0,
                    max: 120.0,
                    activeColor: HmColors.teal,
                    onChanged: (v) {
                      setState(() => _freq = v);
                      _check();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                const Text('AMP ', style: monoStyle),
                Expanded(
                  child: Slider(
                    value: _amp,
                    min: 20.0,
                    max: 100.0,
                    activeColor: HmColors.teal,
                    onChanged: (v) {
                      setState(() => _amp = v);
                      _check();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.freq, this.amp, this.targetFreq, this.targetAmp, this.phase);
  final double freq;
  final double amp;
  final double targetFreq;
  final double targetAmp;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final targetPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final userPaint = Paint()
      ..color = HmColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final targetPath = Path();
    final userPath = Path();

    final midY = size.height / 2;

    for (double x = 0; x < size.width; x++) {
      // Draw target wave
      final tY = midY + math.sin((x / size.width) * targetFreq / 2 + phase * math.pi * 2) * targetAmp;
      if (x == 0) {
        targetPath.moveTo(x, tY);
      } else {
        targetPath.lineTo(x, tY);
      }

      // Draw user wave
      final uY = midY + math.sin((x / size.width) * freq / 2 + phase * math.pi * 2) * amp;
      if (x == 0) {
        userPath.moveTo(x, uY);
      } else {
        userPath.lineTo(x, uY);
      }
    }

    canvas.drawPath(targetPath, targetPaint);
    canvas.drawPath(userPath, userPaint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.freq != freq || old.amp != amp || old.phase != phase;
}

