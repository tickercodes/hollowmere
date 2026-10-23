import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../engine/story_engine.dart';
import 'logic/sudoku.dart';
import 'minigame_scaffold.dart';

/// 9x9 Grid Lock - Caleb's notebook pages. config:
/// {"seed": 1, "size": 9, "givens": 62, "shaded": [[r,c],...], "code_label": "locker 14"}
/// Solving reveals the digits in the shaded cells as a code the story uses.
class SudokuGame extends ConsumerStatefulWidget {
  const SudokuGame({super.key, required this.interaction});
  final MinigameInteraction interaction;
  @override
  ConsumerState<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends ConsumerState<SudokuGame> {
  late final Sudoku _sudoku;
  late List<int> _grid;
  int? _selected;
  bool _solved = false;

  Map<String, dynamic> get cfg => widget.interaction.node.config;
  List<List<int>> get shaded =>
      ((cfg['shaded'] as List?) ?? const []).map((e) => (e as List).cast<int>()).toList();

  @override
  void initState() {
    super.initState();
    final rawGrid = cfg['grid'];
    Sudoku? fromGrid;
    if (rawGrid is List && rawGrid.isNotEmpty) {
      fromGrid = Sudoku.tryFromGrid([
        for (final row in rawGrid) (row as List).map((e) => (e as num).toInt()).toList(),
      ]);
    }
    _sudoku = fromGrid ??
        Sudoku.generate(
          seed: (cfg['seed'] as int?) ?? widget.interaction.puzzleId.hashCode,
          size: (cfg['size'] as int?) ?? (fromGrid == null && rawGrid is List ? 6 : 9),
          givens: (cfg['givens'] as int?) ?? 18,
        );
    _grid = List.of(_sudoku.puzzle);
  }

  bool _isGiven(int i) => _sudoku.puzzle[i] != 0;
  bool _isShaded(int i) => shaded.any((rc) => rc[0] * _sudoku.size + rc[1] == i);

  void _enter(int v) {
    final s = _selected;
    if (s == null || _isGiven(s) || _solved) return;
    setState(() => _grid[s] = v);
    if (!_grid.contains(0) && _sudoku.isSolved(_grid)) _finish();
  }

  bool get _shadedReady => _sudoku.shadedSolved(_grid, shaded);

  void _finish() {
    if (_solved) return;
    setState(() => _solved = true);
    final code = _sudoku.codeAt(shaded);
    ref.read(storyEngineProvider.notifier).applyEffects({
      'notes': [
        {
          'id': 'code_${widget.interaction.puzzleId}',
          'title': (cfg['code_label'] as String?) ?? 'Grid code',
          'body': 'Shaded cells read: $code',
        }
      ],
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) ref.minigameSuccess(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = _sudoku.size;
    final conflicts = _sudoku.conflicts(_grid);
    final code = _solved ? _sudoku.codeAt(shaded) : null;

    return MinigameScaffold(
      interaction: widget.interaction,
      scroll: false,
      brief: cfg['brief'] as String? ??
          'Every row, column and box holds each number once. The shaded cells are the code he hid.',
      bottom: _solved
          ? Container(
              padding: const EdgeInsets.all(16),
              color: HmColors.surface,
              child: Column(
                children: [
                  Text(context.tr('SHADED CELLS READ'),
                      style: monoStyle.copyWith(fontSize: 11, color: HmColors.textDim, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(code!.split('').join(' '), style: displayStyle.copyWith(fontSize: 34, color: HmColors.amber)),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Keypad(size: n, onEnter: _enter, onErase: () => _enter(0)),
                if (_shadedReady)
                  CheckBar(
                    onCheck: _finish,
                    label: 'Complete this game',
                    status: 'Yellow cells match the code.',
                  ),
              ],
            ),
      child: Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: HmColors.paper,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6))],
                ),
                padding: const EdgeInsets.all(6),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: n),
                  itemCount: n * n,
                  itemBuilder: (context, i) {
                    final r = i ~/ n, c = i % n;
                    final v = _grid[i];
                    final sel = _selected == i;
                    final sameVal = _selected != null && _grid[_selected!] != 0 && _grid[_selected!] == v;
                    final thickRight = (c + 1) % _sudoku.boxCols == 0 && c != n - 1;
                    final thickBottom = (r + 1) % _sudoku.boxRows == 0 && r != n - 1;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sel
                              ? HmColors.teal.withValues(alpha: 0.35)
                              : _isShaded(i)
                                  ? HmColors.amber.withValues(alpha: 0.35)
                                  : sameVal
                                      ? HmColors.teal.withValues(alpha: 0.12)
                                      : Colors.transparent,
                          border: Border(
                            left: BorderSide(color: HmColors.paperInk.withValues(alpha: 0.35), width: c == 0 ? 1.8 : 0.5),
                            top: BorderSide(color: HmColors.paperInk.withValues(alpha: 0.35), width: r == 0 ? 1.8 : 0.5),
                            right: BorderSide(color: HmColors.paperInk.withValues(alpha: thickRight ? 0.9 : 0.35), width: thickRight || c == n - 1 ? 1.8 : 0.5),
                            bottom: BorderSide(color: HmColors.paperInk.withValues(alpha: thickBottom ? 0.9 : 0.35), width: thickBottom || r == n - 1 ? 1.8 : 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          v == 0 ? '' : '$v',
                          style: TextStyle(
                            fontSize: n == 9 ? 18 : 22,
                            fontFamily: 'Menlo',
                            fontWeight: _isGiven(i) ? FontWeight.w700 : FontWeight.w400,
                            color: conflicts.contains(i)
                                ? HmColors.danger
                                : _isGiven(i)
                                    ? HmColors.paperInk
                                    : const Color(0xFF1B4D8F),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.size, required this.onEnter, required this.onErase});
  final int size;
  final ValueChanged<int> onEnter;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
            color: HmColors.surface, border: Border(top: BorderSide(color: HmColors.hairline))),
        child: Row(
          children: [
            for (var v = 1; v <= size; v++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: HmColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onEnter(v),
                      child: SizedBox(
                        height: 46,
                        child: Center(child: Text('$v', style: const TextStyle(fontSize: 18))),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: HmColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onErase,
                    child: const SizedBox(
                      height: 46,
                      child: Center(child: Icon(Icons.backspace_outlined, size: 18)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
