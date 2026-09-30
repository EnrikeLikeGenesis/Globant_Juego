import 'dart:math';

enum SudokuDifficulty {
  easy('Fácil', 35),
  medium('Medio', 45),
  hard('Difícil', 52);

  const SudokuDifficulty(this.label, this.emptyCells);

  final String label;
  final int emptyCells;
}

class SudokuLogic {
  static const int size = 9;

  final List<List<int>> solution;
  final List<List<int>> puzzle;
  final List<List<bool>> given;

  SudokuLogic._(this.solution, this.puzzle, this.given);

  factory SudokuLogic.generate(SudokuDifficulty difficulty, {Random? random}) {
    final generator = random ?? Random();
    final solution = List.generate(size, (_) => List.filled(size, 0));
    _fillGrid(solution, generator);
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final cells = List<int>.generate(size * size, (index) => index)
      ..shuffle(generator);
    var removed = 0;

    for (final cell in cells) {
      if (removed == difficulty.emptyCells) break;
      final row = cell ~/ size;
      final column = cell % size;
      final value = puzzle[row][column];
      puzzle[row][column] = 0;

      if (_countSolutions(puzzle) == 1) {
        removed++;
      } else {
        puzzle[row][column] = value;
      }
    }

    final given = puzzle
        .map((row) => row.map((value) => value != 0).toList())
        .toList();
    return SudokuLogic._(solution, puzzle, given);
  }

  static bool _fillGrid(List<List<int>> grid, Random random) {
    final cell = _findBestCell(grid);
    if (cell == null) return true;
    final row = cell ~/ size;
    final column = cell % size;
    final candidates = _candidates(grid, row, column)..shuffle(random);

    for (final value in candidates) {
      grid[row][column] = value;
      if (_fillGrid(grid, random)) return true;
      grid[row][column] = 0;
    }
    return false;
  }

  static int _countSolutions(List<List<int>> source) {
    final grid = source.map((row) => List<int>.from(row)).toList();
    var count = 0;

    void search() {
      if (count >= 2) return;
      final cell = _findBestCell(grid);
      if (cell == null) {
        count++;
        return;
      }
      final row = cell ~/ size;
      final column = cell % size;
      for (final value in _candidates(grid, row, column)) {
        grid[row][column] = value;
        search();
        grid[row][column] = 0;
        if (count >= 2) return;
      }
    }

    search();
    return count;
  }

  static int? _findBestCell(List<List<int>> grid) {
    int? bestCell;
    var fewestCandidates = size + 1;

    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (grid[row][column] != 0) continue;
        final candidates = _candidates(grid, row, column);
        if (candidates.isEmpty) return row * size + column;
        if (candidates.length < fewestCandidates) {
          fewestCandidates = candidates.length;
          bestCell = row * size + column;
        }
      }
    }
    return bestCell;
  }

  static List<int> _candidates(List<List<int>> grid, int row, int column) {
    final used = <int>{
      ...grid[row],
      for (var index = 0; index < size; index++) grid[index][column],
    };
    final boxRow = row ~/ 3 * 3;
    final boxColumn = column ~/ 3 * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxColumn; c < boxColumn + 3; c++) {
        used.add(grid[r][c]);
      }
    }
    return [
      for (var value = 1; value <= size; value++)
        if (!used.contains(value)) value,
    ];
  }
}
