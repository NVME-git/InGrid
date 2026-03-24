import 'dart:math';
import 'board.dart';

enum Difficulty { easy, medium, hard, extreme }

class SudokuGenerator {
  static final Random _rng = Random();

  /// Generate a solved 9x9 board using backtracking.
  static List<List<int>> _generateSolved() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }

  static bool _fillGrid(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          final digits = List.generate(9, (i) => i + 1)..shuffle(_rng);
          for (final d in digits) {
            if (_isValid(grid, r, c, d)) {
              grid[r][c] = d;
              if (_fillGrid(grid)) return true;
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool _isValid(List<List<int>> grid, int row, int col, int digit) {
    for (int c = 0; c < 9; c++) {
      if (c != col && grid[row][c] == digit) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && grid[r][col] == digit) return false;
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if ((r != row || c != col) && grid[r][c] == digit) return false;
      }
    }
    return true;
  }

  /// Count solutions (up to 2 to check uniqueness).
  static int _countSolutions(List<List<int>> grid, int limit) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          int count = 0;
          for (int d = 1; d <= 9; d++) {
            if (_isValid(grid, r, c, d)) {
              grid[r][c] = d;
              count += _countSolutions(grid, limit - count);
              grid[r][c] = 0;
              if (count >= limit) return count;
            }
          }
          return count;
        }
      }
    }
    return 1;
  }

  /// Returns the number of given cells for each difficulty.
  static int _givensForDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy: return 36;
      case Difficulty.medium: return 30;
      case Difficulty.hard: return 26;
      case Difficulty.extreme: return 22;
    }
  }

  /// Generate a puzzle with [difficulty]. Returns a [SudokuBoard] with givens set.
  static SudokuBoard generate(Difficulty difficulty) {
    final solved = _generateSolved();
    final puzzle = List.generate(9, (r) => List<int>.from(solved[r]));

    final targetGivens = _givensForDifficulty(difficulty);
    final positions = [for (int r = 0; r < 9; r++) for (int c = 0; c < 9; c++) (r, c)]
      ..shuffle(_rng);

    int removed = 0;
    for (final (r, c) in positions) {
      if (81 - removed <= targetGivens) break;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;
      // Check uniqueness
      final testGrid = List.generate(9, (row) => List<int>.from(puzzle[row]));
      if (_countSolutions(testGrid, 2) == 1) {
        removed++;
      } else {
        puzzle[r][c] = backup;
      }
    }

    final board = SudokuBoard.empty();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0) {
          board.cells[r][c] = SudokuCell(isGiven: true, digit: puzzle[r][c]);
        }
      }
    }
    return board;
  }
}
