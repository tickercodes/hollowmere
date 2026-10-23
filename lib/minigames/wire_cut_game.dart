import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../engine/story_engine.dart';
import 'minigame_scaffold.dart';

class WireCutGame extends ConsumerStatefulWidget {
  const WireCutGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<WireCutGame> createState() => _WireCutGameState();
}

class _WireCutGameState extends ConsumerState<WireCutGame> {
  final List<String> _cutWires = [];
  bool _exploded = false;

  List<dynamic> get wires => widget.interaction.node.config['wires'] as List<dynamic>;
  List<dynamic> get correctOrder => widget.interaction.node.config['correct_order'] as List<dynamic>;

  void _cut(String wire) async {
    if (_cutWires.contains(wire) || _exploded) return;
    
    setState(() => _cutWires.add(wire));
    
    final index = _cutWires.length - 1;
    if (_cutWires[index] != correctOrder[index]) {
      setState(() => _exploded = true);
      ref.minigameFail(context, widget.interaction.puzzleId, 'Wrong wire! System reset.');
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() {
          _cutWires.clear();
          _exploded = false;
        });
      }
      return;
    }

    if (_cutWires.length == correctOrder.length) {
      ref.minigameSuccess(context, message: 'Disarmed.');
    }
  }

  Color _wireColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red': return Colors.redAccent;
      case 'blue': return Colors.lightBlueAccent;
      case 'green': return Colors.greenAccent;
      case 'yellow': return Colors.amber;
      case 'purple': return Colors.deepPurpleAccent;
      default: return Colors.white;
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
          Icon(_exploded ? Icons.warning_amber_rounded : Icons.precision_manufacturing, 
               color: _exploded ? HmColors.danger : HmColors.teal, size: 48),
          const SizedBox(height: 24),
          for (final wire in wires)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
              child: Row(
                children: [
                  Container(width: 40, height: 20, color: HmColors.surfaceRaised),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _cut(wire as String),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: _cutWires.contains(wire) ? Colors.transparent : _wireColor(wire as String),
                          border: _cutWires.contains(wire) 
                              ? Border.all(color: _wireColor(wire as String).withValues(alpha: 0.3), style: BorderStyle.solid) 
                              : null,
                        ),
                        child: _cutWires.contains(wire) 
                            ? const Center(child: Icon(Icons.close, size: 12, color: Colors.grey))
                            : null,
                      ),
                    ),
                  ),
                  Container(width: 40, height: 20, color: HmColors.surfaceRaised),
                ],
              ),
            ),
          const SizedBox(height: 30),
          Text(context.tr('Tap a wire to cut it.'), style: const TextStyle(color: HmColors.textDim)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

