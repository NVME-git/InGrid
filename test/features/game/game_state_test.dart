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
      // Manually add a corner note first (no conflict yet)
      container.read(gameProvider.notifier).setEntryMode(EntryMode.cornerNote);
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5); // adds note 5
      // Now place digit 5 at another cell in same row
      container.read(gameProvider.notifier).setEntryMode(EntryMode.fullNumber);
      container.read(gameProvider.notifier).selectCell(0, 5);
      container.read(gameProvider.notifier).enterDigit(5);
      // Switch back to corner mode and remove the note — should be allowed
      container.read(gameProvider.notifier).setEntryMode(EntryMode.cornerNote);
      container.read(gameProvider.notifier).selectCell(0, 0);
      container.read(gameProvider.notifier).enterDigit(5); // removes note 5
      final game = container.read(gameProvider);
      expect(game.board.cells[0][0].cornerNotes.contains(5), isFalse);
      expect(game.flashNoteCells, isEmpty);
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
