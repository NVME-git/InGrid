import 'board.dart';

/// Returns set of (row, col) pairs that conflict on the board.
class SudokuValidator {
  static Set<(int, int)> findConflicts(SudokuBoard board) {
    final conflicts = <(int, int)>{};

    // Check rows
    for (int r = 0; r < 9; r++) {
      final seen = <int, List<int>>{};
      for (int c = 0; c < 9; c++) {
        final d = board.cells[r][c].digit;
        if (d != null) {
          seen.putIfAbsent(d, () => []).add(c);
        }
      }
      for (final cols in seen.values) {
        if (cols.length > 1) {
          for (final c in cols) { conflicts.add((r, c)); }
        }
      }
    }

    // Check columns
    for (int c = 0; c < 9; c++) {
      final seen = <int, List<int>>{};
      for (int r = 0; r < 9; r++) {
        final d = board.cells[r][c].digit;
        if (d != null) {
          seen.putIfAbsent(d, () => []).add(r);
        }
      }
      for (final rows in seen.values) {
        if (rows.length > 1) {
          for (final r in rows) { conflicts.add((r, c)); }
        }
      }
    }

    // Check 3x3 boxes
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        final seen = <int, List<(int, int)>>{};
        for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
          for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
            final d = board.cells[r][c].digit;
            if (d != null) {
              seen.putIfAbsent(d, () => []).add((r, c));
            }
          }
        }
        for (final positions in seen.values) {
          if (positions.length > 1) {
            for (final pos in positions) { conflicts.add(pos); }
          }
        }
      }
    }

    return conflicts;
  }

  /// Check if placing [digit] at [row],[col] causes a conflict (ignoring the cell itself).
  static bool isValidPlacement(SudokuBoard board, int row, int col, int digit) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (c != col && board.cells[row][c].digit == digit) return false;
    }
    // Check column
    for (int r = 0; r < 9; r++) {
      if (r != row && board.cells[r][col].digit == digit) return false;
    }
    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if ((r != row || c != col) && board.cells[r][c].digit == digit) return false;
      }
    }
    return true;
  }
}
