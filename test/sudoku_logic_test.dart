import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mascota_virtual/game/sudoku_logic.dart';

void main() {
  test('generated puzzles match the selected difficulty and solution', () {
    for (final difficulty in SudokuDifficulty.values) {
      final game = SudokuLogic.generate(difficulty, random: Random(12));
      final emptyCells = game.puzzle
          .expand((row) => row)
          .where((value) => value == 0)
          .length;

      expect(emptyCells, difficulty.emptyCells);
      expect(
        game.solution.expand((row) => row),
        everyElement(inInclusiveRange(1, 9)),
      );
      for (var row = 0; row < 9; row++) {
        expect(game.solution[row].toSet().length, 9);
        expect(
          List.generate(
            9,
            (column) => game.solution[column][row],
          ).toSet().length,
          9,
        );
      }
      for (var row = 0; row < 9; row++) {
        for (var column = 0; column < 9; column++) {
          if (game.puzzle[row][column] != 0) {
            expect(game.puzzle[row][column], game.solution[row][column]);
          }
        }
      }
    }
  });
}
