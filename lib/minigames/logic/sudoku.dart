import 'dart:math' as math;

/// Deterministic Sudoku generation and solving (9x9 or 6x6).
///
/// Puzzles are generated from a seed so the same episode always yields the
/// same grid, which matters because the shaded-cell digits form a story code.
/// Uniqueness is enforced while removing givens, so the code is unambiguous.
class Sudoku {
  Sudoku._(this.size, this.solution, this.puzzle);

  final int size;

  /// Row-major solved grid, values 1..size.
  final List<int> solution;

  /// Row-major puzzle, 0 for empty.
  final List<int> puzzle;

  int get boxRows => size == 6 ? 2 : size == 3 ? 1 : 3;
  int get boxCols => size == 6 ? 3 : size == 3 ? 1 : 3;

  /// Builds a puzzle from an explicit grid. Returns null when the grid is
  /// not a square of 3/6/9 or contains values larger than [size].
  static Sudoku? tryFromGrid(List<List<int>> rows) {
    if (rows.isEmpty) return null;
    final size = rows.length;
    if (size != 3 && size != 6 && size != 9) return null;
    if (rows.any((r) => r.length != size)) return null;
    final puzzle = [for (final r in rows) ...r];
    if (puzzle.any((v) => v < 0 || v > size)) return null;
    final solution = List<int>.from(puzzle);
    if (countSolutions(puzzle, size, limit: 2, writeInto: solution) != 1) {
      return null;
    }
    return Sudoku._(size, solution, puzzle);
  }

  static Sudoku generate({required int seed, int size = 9, required int givens}) {
    assert(size == 9 || size == 6 || size == 3, 'Unsupported size');
    final rng = math.Random(seed);
    final solution = _solvedGrid(size, rng);
    final puzzle = List<int>.from(solution);
    final order = List.generate(size * size, (i) => i)..shuffle(rng);
    var remaining = size * size;
    for (final idx in order) {
      if (remaining <= givens) break;
      final saved = puzzle[idx];
      puzzle[idx] = 0;
      if (countSolutions(puzzle, size, limit: 2) != 1) {
        puzzle[idx] = saved;
      } else {
        remaining--;
      }
    }
    return Sudoku._(size, solution, puzzle);
  }

  /// A fully solved grid: pattern-fill then shuffle digits, rows within bands,
  /// bands, columns within stacks, and stacks. Always valid.
  static List<int> _solvedGrid(int size, math.Random rng) {
    final br = size == 6 ? 2 : size == 3 ? 1 : 3;
    final bc = size == 6 ? 3 : size == 3 ? 1 : 3;
    int pattern(int r, int c) => (bc * (r % br) + r ~/ br + c) % size;

    final digits = List.generate(size, (i) => i + 1)..shuffle(rng);
    List<int> shuffledRange(int n) => List.generate(n, (i) => i)..shuffle(rng);

    final rows = <int>[];
    for (final band in shuffledRange(size ~/ br)) {
      for (final r in shuffledRange(br)) {
        rows.add(band * br + r);
      }
    }
    final cols = <int>[];
    for (final stack in shuffledRange(size ~/ bc)) {
      for (final c in shuffledRange(bc)) {
        cols.add(stack * bc + c);
      }
    }
    return [
      for (final r in rows)
        for (final c in cols) digits[pattern(r, c)]
    ];
  }

  /// Counts solutions up to [limit] using backtracking with MRV ordering.
  static int countSolutions(List<int> grid, int size, {int limit = 2, List<int>? writeInto}) {
    final g = List<int>.from(grid);
    var count = 0;
    final br = size == 6 ? 2 : size == 3 ? 1 : 3;
    final bc = size == 6 ? 3 : size == 3 ? 1 : 3;

    bool ok(int idx, int v) {
      final r = idx ~/ size, c = idx % size;
      for (var i = 0; i < size; i++) {
        if (g[r * size + i] == v || g[i * size + c] == v) return false;
      }
      final r0 = (r ~/ br) * br, c0 = (c ~/ bc) * bc;
      for (var rr = r0; rr < r0 + br; rr++) {
        for (var cc = c0; cc < c0 + bc; cc++) {
          if (g[rr * size + cc] == v) return false;
        }
      }
      return true;
    }

    void solve() {
      if (count >= limit) return;
      // Most-constrained empty cell first.
      var best = -1;
      var bestOptions = size + 1;
      List<int>? bestVals;
      for (var i = 0; i < g.length; i++) {
        if (g[i] != 0) continue;
        final vals = [for (var v = 1; v <= size; v++) if (ok(i, v)) v];
        if (vals.length < bestOptions) {
          best = i;
          bestOptions = vals.length;
          bestVals = vals;
          if (vals.isEmpty) break;
        }
      }
      if (best == -1) {
        count++;
        if (writeInto != null && count == 1) {
          for (var i = 0; i < g.length; i++) {
            writeInto[i] = g[i];
          }
        }
        return;
      }
      for (final v in bestVals!) {
        g[best] = v;
        solve();
        if (count >= limit) return;
      }
      g[best] = 0;
    }

    solve();
    return count;
  }

  /// True when [attempt] equals the unique solution.
  bool isSolved(List<int> attempt) {
    if (attempt.length != solution.length) return false;
    for (var i = 0; i < attempt.length; i++) {
      if (attempt[i] != solution[i]) return false;
    }
    return true;
  }

  /// Cells whose current value conflicts with another in its row/col/box.
  Set<int> conflicts(List<int> grid) {
    final out = <int>{};
    for (var i = 0; i < grid.length; i++) {
      final v = grid[i];
      if (v == 0) continue;
      final r = i ~/ size, c = i % size;
      for (var j = 0; j < size; j++) {
        final ri = r * size + j, ci = j * size + c;
        if (ri != i && grid[ri] == v) out.addAll([i, ri]);
        if (ci != i && grid[ci] == v) out.addAll([i, ci]);
      }
      final r0 = (r ~/ boxRows) * boxRows, c0 = (c ~/ boxCols) * boxCols;
      for (var rr = r0; rr < r0 + boxRows; rr++) {
        for (var cc = c0; cc < c0 + boxCols; cc++) {
          final k = rr * size + cc;
          if (k != i && grid[k] == v) out.addAll([i, k]);
        }
      }
    }
    return out;
  }

  /// Digits at the given (row, col) cells of the solution, as a string.
  String codeAt(List<List<int>> cells) =>
      cells.map((rc) => solution[rc[0] * size + rc[1]]).join();

  /// True when every shaded cell on [attempt] matches the unique solution.
  bool shadedSolved(List<int> attempt, List<List<int>> cells) {
    if (cells.isEmpty) return false;
    for (final rc in cells) {
      final i = rc[0] * size + rc[1];
      if (attempt[i] == 0 || attempt[i] != solution[i]) return false;
    }
    return true;
  }
}
