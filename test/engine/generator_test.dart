import 'package:test/test.dart';
import 'package:ingrid/core/engine/engine.dart';

void main() {
  group('SudokuGenerator', () {
    test('generates a valid board with the correct number of givens for easy', () {
      final board = SudokuGenerator.generate(Difficulty.easy);
      int givens = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (board.cells[r][c].digit != null) givens++;
        }
      }
      expect(givens, greaterThanOrEqualTo(30));
      expect(givens, lessThanOrEqualTo(81));
    });

    test('generates a valid board with fewer givens for extreme', () {
      final easy = SudokuGenerator.generate(Difficulty.easy);
      final extreme = SudokuGenerator.generate(Difficulty.extreme);

      int easyGivens = 0;
      int extremeGivens = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (easy.cells[r][c].digit != null) easyGivens++;
          if (extreme.cells[r][c].digit != null) extremeGivens++;
        }
      }
      expect(easyGivens, greaterThan(extremeGivens));
    });

    test('generated board has no conflicts', () {
      for (final diff in Difficulty.values) {
        final board = SudokuGenerator.generate(diff);
        final conflicts = SudokuValidator.findConflicts(board);
        expect(conflicts, isEmpty, reason: 'Conflict found for $diff');
      }
    });

    test('generates different boards on repeated calls', () {
      final b1 = SudokuGenerator.generate(Difficulty.medium);
      final b2 = SudokuGenerator.generate(Difficulty.medium);
      bool different = false;
      outer:
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (b1.cells[r][c].digit != b2.cells[r][c].digit) {
            different = true;
            break outer;
          }
        }
      }
      expect(different, isTrue);
    });
  });
}
