import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/engine/engine.dart';

enum EntryMode { fullNumber, cornerNote, centreNote, highlighter }

// Highlighter color palette (9 colors + X)
const kHighlightColors = [
  0xFF4CAF50, // green
  0xFFFF9800, // orange  
  0xFFF44336, // red
  0xFF2196F3, // blue
  0xFF9C27B0, // purple
  0xFFFFEB3B, // yellow
  0xFF00BCD4, // cyan
  0xFFFF69B4, // pink
  0xFF795548, // brown
];

class GameState {
  final SudokuBoard board;
  final Set<(int, int)> selectedCells;
  final EntryMode entryMode;
  final int highlightColorIndex; // 0-8 for colors, -1 for X
  final bool showConflicts;
  final Difficulty difficulty;
  final Duration elapsed;
  final bool isComplete;
  final Set<(int, int)> conflicts;
  /// When true, tapping cells adds/removes from selection rather than replacing it.
  /// Active for fullNumber, cornerNote, centreNote modes.
  final bool multiSelectMode;
  // Transient flash state for note-conflict validation (cleared after ~800 ms)
  final Set<(int, int)> flashConflictCells; // existing-digit cells highlighted red
  final Set<(int, int)> flashNoteCells;     // cells where invalid note was attempted
  final int? flashNoteDigit;                // the digit that was rejected
  final EntryMode? flashNoteMode;           // cornerNote or centreNote

  const GameState({
    required this.board,
    this.selectedCells = const {},
    this.entryMode = EntryMode.fullNumber,
    this.highlightColorIndex = 0,
    this.showConflicts = true,
    this.difficulty = Difficulty.medium,
    this.elapsed = Duration.zero,
    this.isComplete = false,
    this.conflicts = const {},
    this.multiSelectMode = false,
    this.flashConflictCells = const {},
    this.flashNoteCells = const {},
    this.flashNoteDigit,
    this.flashNoteMode,
  });

  GameState copyWith({
    SudokuBoard? board,
    Set<(int, int)>? selectedCells,
    EntryMode? entryMode,
    int? highlightColorIndex,
    bool? showConflicts,
    Difficulty? difficulty,
    Duration? elapsed,
    bool? isComplete,
    Set<(int, int)>? conflicts,
    bool? multiSelectMode,
    Set<(int, int)>? flashConflictCells,
    Set<(int, int)>? flashNoteCells,
    int? flashNoteDigit,
    EntryMode? flashNoteMode,
    // Pass clearFlash: true to explicitly null-out all flash fields.
    bool clearFlash = false,
  }) {
    return GameState(
      board: board ?? this.board,
      selectedCells: selectedCells ?? this.selectedCells,
      entryMode: entryMode ?? this.entryMode,
      highlightColorIndex: highlightColorIndex ?? this.highlightColorIndex,
      showConflicts: showConflicts ?? this.showConflicts,
      difficulty: difficulty ?? this.difficulty,
      elapsed: elapsed ?? this.elapsed,
      isComplete: isComplete ?? this.isComplete,
      conflicts: conflicts ?? this.conflicts,
      multiSelectMode: multiSelectMode ?? this.multiSelectMode,
      flashConflictCells: clearFlash ? const {} : (flashConflictCells ?? this.flashConflictCells),
      flashNoteCells: clearFlash ? const {} : (flashNoteCells ?? this.flashNoteCells),
      flashNoteDigit: clearFlash ? null : (flashNoteDigit ?? this.flashNoteDigit),
      flashNoteMode: clearFlash ? null : (flashNoteMode ?? this.flashNoteMode),
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  final MoveRecorder _recorder = MoveRecorder();
  // Undo stack stores board snapshots
  final List<SudokuBoard> _undoStack = [];
  final List<SudokuBoard> _redoStack = [];
  // Cancellable timer for clearing transient flash state
  Timer? _flashTimer;

  @override
  GameState build() {
    return GameState(
      board: SudokuBoard.empty(),
    );
  }

  void startNewGame(Difficulty difficulty) {
    _recorder.clear();
    _undoStack.clear();
    _redoStack.clear();
    final board = SudokuGenerator.generate(difficulty);
    state = GameState(
      board: board,
      difficulty: difficulty,
      conflicts: SudokuValidator.findConflicts(board),
    );
  }

  void startManualEntry() {
    _recorder.clear();
    _undoStack.clear();
    _redoStack.clear();
    state = GameState(board: SudokuBoard.empty());
  }

  void selectCell(int row, int col, {bool toggle = false, bool addToSelection = false}) {
    // In multi-select mode (for digit/note modes) a tap adds/removes the cell
    final effectiveAdd = addToSelection ||
        (state.multiSelectMode && state.entryMode != EntryMode.highlighter);
    Set<(int, int)> newSelection;
    if (effectiveAdd) {
      newSelection = Set.from(state.selectedCells);
      if (newSelection.contains((row, col))) {
        newSelection.remove((row, col));
      } else {
        newSelection.add((row, col));
      }
    } else {
      if (toggle && state.selectedCells.contains((row, col)) && state.selectedCells.length == 1) {
        newSelection = {};
      } else {
        newSelection = {(row, col)};
      }
    }
    state = state.copyWith(selectedCells: newSelection);
  }

  void toggleMultiSelect() {
    state = state.copyWith(multiSelectMode: !state.multiSelectMode);
  }

  void deselectAll() {
    state = state.copyWith(selectedCells: const {});
  }

  void setEntryMode(EntryMode mode) {
    state = state.copyWith(entryMode: mode);
  }

  void setHighlightColor(int index) {
    state = state.copyWith(highlightColorIndex: index);
  }

  void enterDigit(int digit) {
    if (state.selectedCells.isEmpty) return;

    final newBoard = state.board.copy();
    final affected = <(int, int)>[];
    final flashConflict = <(int, int)>{};
    final flashNote = <(int, int)>{};
    final entryMode = state.entryMode;

    for (final (r, c) in state.selectedCells) {
      final cell = newBoard.cells[r][c];
      if (cell.isGiven) continue;

      switch (entryMode) {
        case EntryMode.fullNumber:
          cell.digit = digit;
          cell.cornerNotes.clear();
          cell.centreNotes.clear();
          affected.add((r, c));
          break;
        case EntryMode.cornerNote:
          // Only block *adding* a note that conflicts; removal is always allowed.
          if (!cell.cornerNotes.contains(digit)) {
            final peers = _findNoteConflicts(newBoard, r, c, digit);
            if (peers.isNotEmpty) {
              flashConflict.addAll(peers);
              flashNote.add((r, c));
              break;
            }
          }
          if (cell.cornerNotes.contains(digit)) {
            cell.cornerNotes.remove(digit);
          } else {
            cell.cornerNotes.add(digit);
          }
          affected.add((r, c));
          break;
        case EntryMode.centreNote:
          if (!cell.centreNotes.contains(digit)) {
            final peers = _findNoteConflicts(newBoard, r, c, digit);
            if (peers.isNotEmpty) {
              flashConflict.addAll(peers);
              flashNote.add((r, c));
              break;
            }
          }
          if (cell.centreNotes.contains(digit)) {
            cell.centreNotes.remove(digit);
          } else {
            cell.centreNotes.add(digit);
          }
          affected.add((r, c));
          break;
        case EntryMode.highlighter:
          cell.highlightColor = state.highlightColorIndex;
          affected.add((r, c));
          break;
      }
    }

    // Save undo only when the board actually changed.
    if (affected.isNotEmpty) {
      _saveUndoSnapshot();
      _redoStack.clear();
    }

    // Handle note-conflict flash (may coexist with valid changes in other cells).
    if (flashNote.isNotEmpty) {
      _flashTimer?.cancel();
      var newState = state.copyWith(
        flashConflictCells: flashConflict,
        flashNoteCells: flashNote,
        flashNoteDigit: digit,
        flashNoteMode: entryMode,
      );
      if (affected.isNotEmpty) {
        final boardConflicts = SudokuValidator.findConflicts(newBoard);
        newState = newState.copyWith(
          board: newBoard,
          conflicts: boardConflicts,
          isComplete: newBoard.isSolved && boardConflicts.isEmpty,
        );
      }
      state = newState;
      _flashTimer = Timer(const Duration(milliseconds: 800), () {
        if (state.flashNoteCells.isNotEmpty) {
          state = state.copyWith(clearFlash: true);
        }
      });
      if (affected.isNotEmpty) {
        _recorder.record(MoveRecord(
          type: entryMode == EntryMode.cornerNote
              ? MoveType.addCornerNote
              : MoveType.addCentreNote,
          timestamp: DateTime.now(),
          cells: affected,
          value: digit,
        ));
      }
      return;
    }

    if (affected.isEmpty) return;

    _recorder.record(MoveRecord(
      type: entryMode == EntryMode.fullNumber
          ? MoveType.placeDigit
          : entryMode == EntryMode.cornerNote
              ? MoveType.addCornerNote
              : entryMode == EntryMode.centreNote
                  ? MoveType.addCentreNote
                  : MoveType.highlight,
      timestamp: DateTime.now(),
      cells: affected,
      value: digit,
    ));

    final conflicts = SudokuValidator.findConflicts(newBoard);
    final complete = newBoard.isSolved && conflicts.isEmpty;

    state = state.copyWith(
      board: newBoard,
      isComplete: complete,
      conflicts: conflicts,
    );
  }

  /// Returns the cells in the same row, column, or 3×3 box as [row],[col]
  /// that already contain [digit]. An empty set means no conflict.
  Set<(int, int)> _findNoteConflicts(SudokuBoard board, int row, int col, int digit) {
    final result = <(int, int)>{};
    for (int c = 0; c < 9; c++) {
      if (c != col && board.cells[row][c].digit == digit) result.add((row, c));
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && board.cells[r][col].digit == digit) result.add((r, col));
    }
    final boxR = (row ~/ 3) * 3;
    final boxC = (col ~/ 3) * 3;
    for (int r = boxR; r < boxR + 3; r++) {
      for (int c = boxC; c < boxC + 3; c++) {
        if ((r != row || c != col) && board.cells[r][c].digit == digit) {
          result.add((r, c));
        }
      }
    }
    return result;
  }

  void erase({bool fullClear = false}) {
    if (state.selectedCells.isEmpty) return;
    _saveUndoSnapshot();
    _redoStack.clear();

    final newBoard = state.board.copy();
    final affected = <(int, int)>[];

    for (final (r, c) in state.selectedCells) {
      final cell = newBoard.cells[r][c];
      if (cell.isGiven) continue;

      if (fullClear) {
        cell.digit = null;
        cell.cornerNotes.clear();
        cell.centreNotes.clear();
        cell.highlightColor = null;
        affected.add((r, c));
      } else {
        // Smart erase: clear current mode entries first
        switch (state.entryMode) {
          case EntryMode.fullNumber:
            if (cell.digit != null) {
              cell.digit = null;
              affected.add((r, c));
            } else if (cell.cornerNotes.isNotEmpty || cell.centreNotes.isNotEmpty) {
              cell.cornerNotes.clear();
              cell.centreNotes.clear();
              affected.add((r, c));
            }
            break;
          case EntryMode.cornerNote:
            if (cell.cornerNotes.isNotEmpty) {
              cell.cornerNotes.clear();
              affected.add((r, c));
            }
            break;
          case EntryMode.centreNote:
            if (cell.centreNotes.isNotEmpty) {
              cell.centreNotes.clear();
              affected.add((r, c));
            }
            break;
          case EntryMode.highlighter:
            if (cell.highlightColor != null) {
              cell.highlightColor = null;
              affected.add((r, c));
            }
            break;
        }
      }
    }

    if (affected.isEmpty) return;

    _recorder.record(MoveRecord(
      type: MoveType.erase,
      timestamp: DateTime.now(),
      cells: affected,
    ));

    final conflicts = SudokuValidator.findConflicts(newBoard);
    state = state.copyWith(board: newBoard, conflicts: conflicts, isComplete: false);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(state.board);
    final prevBoard = _undoStack.removeLast();
    final conflicts = SudokuValidator.findConflicts(prevBoard);
    state = state.copyWith(board: prevBoard, conflicts: conflicts, isComplete: false);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(state.board);
    final nextBoard = _redoStack.removeLast();
    final conflicts = SudokuValidator.findConflicts(nextBoard);
    final complete = nextBoard.isSolved && conflicts.isEmpty;
    state = state.copyWith(board: nextBoard, conflicts: conflicts, isComplete: complete);
  }

  void updateTimer(Duration elapsed) {
    state = state.copyWith(elapsed: elapsed);
  }

  void toggleConflicts() {
    state = state.copyWith(showConflicts: !state.showConflicts);
  }

  void _saveUndoSnapshot() {
    _undoStack.add(state.board.copy());
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
