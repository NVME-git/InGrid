import 'package:flutter_test/flutter_test.dart';
import 'package:ingrid/core/engine/engine.dart';

SudokuBoard _boardFromGrid(List<List<int>> grid) {
  final board = SudokuBoard.empty();
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (grid[r][c] != 0) {
        board.cells[r][c] = SudokuCell(isGiven: true, digit: grid[r][c]);
      }
    }
  }
  return board;
}

void main() {
  group('SudokuValidator', () {
    test('empty board has no conflicts', () {
      final board = SudokuBoard.empty();
      expect(SudokuValidator.findConflicts(board), isEmpty);
    });

    test('detects row conflict', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 5;
      grid[0][5] = 5;
      final board = _boardFromGrid(grid);
      final conflicts = SudokuValidator.findConflicts(board);
      expect(conflicts, contains((0, 0)));
      expect(conflicts, contains((0, 5)));
    });

    test('detects column conflict', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][3] = 7;
      grid[6][3] = 7;
      final board = _boardFromGrid(grid);
      final conflicts = SudokuValidator.findConflicts(board);
      expect(conflicts, contains((0, 3)));
      expect(conflicts, contains((6, 3)));
    });

    test('detects box conflict', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[0][0] = 3;
      grid[2][2] = 3;
      final board = _boardFromGrid(grid);
      final conflicts = SudokuValidator.findConflicts(board);
      expect(conflicts, contains((0, 0)));
      expect(conflicts, contains((2, 2)));
    });

    test('no false positives for valid board', () {
      final grid = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.findConflicts(board), isEmpty);
    });

    test('isValidPlacement detects row conflict', () {
      final grid = List.generate(9, (_) => List.filled(9, 0));
      grid[2][4] = 6;
      final board = _boardFromGrid(grid);
      expect(SudokuValidator.isValidPlacement(board, 2, 0, 6), isFalse);
      expect(SudokuValidator.isValidPlacement(board, 2, 0, 5), isTrue);
    });
  });
}
