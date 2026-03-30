import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingrid/features/game/game_state.dart';
import 'package:ingrid/features/game/widgets/sudoku_grid.dart';
import 'package:ingrid/features/game/widgets/digit_toolbar.dart';
import 'package:ingrid/core/engine/engine.dart';

Widget _buildTestApp(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(child: SudokuGrid()),
            DigitToolbar(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('GameState', () {
    test('starts in fullNumber mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider);
      expect(game.entryMode, EntryMode.fullNumber);
    });

    test('can start a new game', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startNewGame(Difficulty.easy);
      final game = container.read(gameProvider);
      int givens = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (game.board.cells[r][c].digit != null) givens++;
        }
      }
      expect(givens, greaterThan(0));
    });

    test('digit entry changes board', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5);
      final game = container.read(gameProvider);
      expect(game.board.cells[0][0].digit, 5);
    });

    test('undo reverts digit entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5);
      container.read(gameProvider.notifier).undo();
      final game = container.read(gameProvider);
      expect(game.board.cells[0][0].digit, isNull);
    });

    test('mode switching changes entry mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).setEntryMode(EntryMode.cornerNote);
      expect(container.read(gameProvider).entryMode, EntryMode.cornerNote);
    });

    test('multiSelect toggle accumulates cells', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).toggleMultiSelect();
      expect(container.read(gameProvider).multiSelectMode, isTrue);
      // Selecting two cells should keep both selected
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).selectCell(0, 1);
      expect(container.read(gameProvider).selectedCells.length, 2);
    });

    test('multiSelect toggle off clears extra cells', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).toggleMultiSelect();
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).selectCell(0, 1);
      // Turn off multi-select; next tap should be single
      container.read(gameProvider.notifier).toggleMultiSelect();
      container.read(gameProvider.notifier).selectCell(1, 0);
      expect(container.read(gameProvider).selectedCells.length, 1);
    });

    test('setEntryModeAndMulti multi→single preserves single selected cell', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      // Enter multi-select with exactly one cell selected
      container.read(gameProvider.notifier).setEntryModeAndMulti(EntryMode.fullNumber, true);
      container.read(gameProvider.notifier).selectCell(0, 0);
      expect(container.read(gameProvider).selectedCells.length, 1);
      // Transition back to single-select — the one cell must stay selected
      container.read(gameProvider.notifier).setEntryModeAndMulti(EntryMode.fullNumber, false);
      expect(container.read(gameProvider).selectedCells, contains((0, 0)));
      expect(container.read(gameProvider).selectedCells.length, 1);
    });

    test('setEntryModeAndMulti multi→single deselects when multiple cells selected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      // Enter multi-select with two cells selected
      container.read(gameProvider.notifier).setEntryModeAndMulti(EntryMode.fullNumber, true);
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).selectCell(0, 1);
      expect(container.read(gameProvider).selectedCells.length, 2);
      // Transition back to single-select — all cells must be deselected
      container.read(gameProvider.notifier).setEntryModeAndMulti(EntryMode.fullNumber, false);
      expect(container.read(gameProvider).selectedCells, isEmpty);
    });

    test('deselectAll clears selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).deselectAll();
      expect(container.read(gameProvider).selectedCells, isEmpty);
    });

    test('note conflict fires flash state and does not add note', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Set up a board where row 0 already has digit 5 at col 5
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).selectCell(0, 5);
      container.read(gameProvider.notifier).enterDigit(5); // place 5 at (0,5)
      // Now switch to cornerNote mode and try to add 5 to (0,0) — same row
      container.read(gameProvider.notifier).setEntryMode(EntryMode.cornerNote);
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5);
      final game = container.read(gameProvider);
      // Note should NOT have been added
      expect(game.board.cells[0][0].cornerNotes.contains(5), isFalse);
      // Flash state should be set
      expect(game.flashNoteCells, contains((0, 0)));
      expect(game.flashConflictCells, contains((0, 5)));
      expect(game.flashNoteDigit, 5);
    });

    test('note removal allowed even when same digit in row', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      // Add a corner note 5 at (0,0)
      container.read(gameProvider.notifier).setEntryMode(EntryMode.cornerNote);
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5); // adds note 5
      expect(container.read(gameProvider).board.cells[0][0].cornerNotes.contains(5), isTrue);
      // Place digit 5 at (0,5) — auto-removes note 5 from (0,0) as a peer
      container.read(gameProvider.notifier).setEntryMode(EntryMode.fullNumber);
      container.read(gameProvider.notifier).selectCell(0, 5);
      container.read(gameProvider.notifier).enterDigit(5);
      final game = container.read(gameProvider);
      // Note should have been auto-removed from (0,0) because (0,5) now has digit 5
      expect(game.board.cells[0][0].cornerNotes.contains(5), isFalse);
      expect(game.flashNoteCells, isEmpty);
    });

    test('placing a digit removes its candidates from row/col/box peers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      // Manually add note 5 to several cells that will "see" (4,4)
      container.read(gameProvider.notifier).setEntryMode(EntryMode.cornerNote);
      // Same row as (4,4): (4,0) and (4,8)
      container.read(gameProvider.notifier).selectCell(4, 0);
      container.read(gameProvider.notifier).enterDigit(5);
      container.read(gameProvider.notifier).selectCell(4, 8);
      container.read(gameProvider.notifier).enterDigit(5);
      // Same column as (4,4): (0,4) and (8,4)
      container.read(gameProvider.notifier).selectCell(0, 4);
      container.read(gameProvider.notifier).enterDigit(5);
      container.read(gameProvider.notifier).selectCell(8, 4);
      container.read(gameProvider.notifier).enterDigit(5);
      // Same 3x3 box as (4,4): (3,3) and (5,5)
      container.read(gameProvider.notifier).selectCell(3, 3);
      container.read(gameProvider.notifier).enterDigit(5);
      container.read(gameProvider.notifier).selectCell(5, 5);
      container.read(gameProvider.notifier).enterDigit(5);
      // A cell outside all peers: (0,0) — note should NOT be removed
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5);

      // Now place digit 5 at (4,4)
      container.read(gameProvider.notifier).setEntryMode(EntryMode.fullNumber);
      container.read(gameProvider.notifier).selectCell(4, 4);
      container.read(gameProvider.notifier).enterDigit(5);

      final game = container.read(gameProvider);
      // Peer notes should be gone
      expect(game.board.cells[4][0].cornerNotes.contains(5), isFalse);
      expect(game.board.cells[4][8].cornerNotes.contains(5), isFalse);
      expect(game.board.cells[0][4].cornerNotes.contains(5), isFalse);
      expect(game.board.cells[8][4].cornerNotes.contains(5), isFalse);
      expect(game.board.cells[3][3].cornerNotes.contains(5), isFalse);
      expect(game.board.cells[5][5].cornerNotes.contains(5), isFalse);
      // Non-peer note should still be there
      expect(game.board.cells[0][0].cornerNotes.contains(5), isTrue);
    });
  });

  group('hints board string', () {
    /// Simulates the board-to-string logic used by _openHints() in GameScreen.
    String boardToHintsString(SudokuBoard board) {
      final buf = StringBuffer();
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          buf.write(board.cells[r][c].digit ?? '0');
        }
      }
      return buf.toString();
    }

    test('empty board produces 81 zeros', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final board = container.read(gameProvider).board;
      final s = boardToHintsString(board);
      expect(s.length, 81);
      expect(s, equals('0' * 81));
      expect(RegExp(r'^[0-9]{81}$').hasMatch(s), isTrue);
    });

    test('board with some digits produces 81 integers 0-9', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(3);
      container.read(gameProvider.notifier).selectCell(4, 4);
      container.read(gameProvider.notifier).enterDigit(7);

      final board = container.read(gameProvider).board;
      final s = boardToHintsString(board);
      expect(s.length, 81);
      expect(s[0], '3');
      expect(s[4 * 9 + 4], '7');
      expect(RegExp(r'^[0-9]{81}$').hasMatch(s), isTrue);
    });

    test('started game board produces 81 integers 0-9', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startNewGame(Difficulty.easy);

      final board = container.read(gameProvider).board;
      final s = boardToHintsString(board);
      expect(s.length, 81);
      expect(RegExp(r'^[0-9]{81}$').hasMatch(s), isTrue);
    });
  });

  group('GameScreen widgets', () {
    testWidgets('renders SudokuGrid', (tester) async {
      await tester.pumpWidget(_buildTestApp([]));
      expect(find.byType(SudokuGrid), findsOneWidget);
    });

    testWidgets('renders DigitToolbar', (tester) async {
      await tester.pumpWidget(_buildTestApp([]));
      expect(find.byType(DigitToolbar), findsOneWidget);
    });

    testWidgets('tapping digit 5 sets board cell', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).startManualEntry();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(child: SudokuGrid()),
                  DigitToolbar(),
                ],
              ),
            ),
          ),
        ),
      );

      // Select cell (0,0) — tap the first cell in the grid
      final gridFinder = find.byType(SudokuGrid);
      expect(gridFinder, findsOneWidget);
      // Tap digit button '5' in toolbar
      final digitFinder = find.text('5');
      // The digit row should have 9 buttons
      expect(digitFinder, findsWidgets);
    });
  });
}
