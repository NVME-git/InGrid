import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/engine/engine.dart';
import '../../services/persistence_service.dart';
import '../../services/session_service.dart';

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
  /// When set (and selectedCells is empty), tints all cells containing this digit
  /// with the same-value highlight — used by the long-press digit action.
  final int? pinnedDigit;
  /// When true, every empty cell that has no user-written notes shows its
  /// computed valid candidates as dim corner notes.
  final bool autoCandidates;
  /// When true the timer is stopped and a pause overlay hides the grid.
  final bool isPaused;
  /// When true, this game was imported via a string or the manual grid.
  final bool isImported;
  /// The 81-char givens string saved when the game was first started,
  /// used to record the original puzzle in history.
  final String initialBoard;

  const GameState({
    required this.board,
    this.selectedCells = const {},
    this.entryMode = EntryMode.fullNumber,
    this.highlightColorIndex = 0,
    this.showConflicts = false,
    this.difficulty = Difficulty.medium,
    this.elapsed = Duration.zero,
    this.isComplete = false,
    this.conflicts = const {},
    this.multiSelectMode = false,
    this.flashConflictCells = const {},
    this.flashNoteCells = const {},
    this.flashNoteDigit,
    this.flashNoteMode,
    this.pinnedDigit,
    this.autoCandidates = false,
    this.isPaused = false,
    this.isImported = false,
    this.initialBoard = '',
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
    int? pinnedDigit,
    // Pass clearPinnedDigit: true to null-out the pinned digit highlight.
    bool clearPinnedDigit = false,
    bool? autoCandidates,
    bool? isPaused,
    bool? isImported,
    String? initialBoard,
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
      pinnedDigit: clearPinnedDigit ? null : (pinnedDigit ?? this.pinnedDigit),
      autoCandidates: autoCandidates ?? this.autoCandidates,
      isPaused: isPaused ?? this.isPaused,
      isImported: isImported ?? this.isImported,
      initialBoard: initialBoard ?? this.initialBoard,
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
    final initialBoard = PersistenceService.boardToGivensString(board);
    state = GameState(
      board: board,
      difficulty: difficulty,
      conflicts: SudokuValidator.findConflicts(board),
      initialBoard: initialBoard,
    );
    SessionService.gameSessionActive = true;
    _autoSave();
  }

  void startManualEntry() {
    _recorder.clear();
    _undoStack.clear();
    _redoStack.clear();
    state = GameState(board: SudokuBoard.empty());
    PersistenceService.clearCurrentGame();
  }

  /// Starts a game from an imported 81-char digit string (0 = empty, 1-9 = given).
  void startImportedGame(String board81) {
    _recorder.clear();
    _undoStack.clear();
    _redoStack.clear();
    final board = PersistenceService.boardFromString(board81);
    state = GameState(
      board: board,
      difficulty: Difficulty.medium,
      conflicts: SudokuValidator.findConflicts(board),
      initialBoard: board81,
      isImported: true,
    );
    SessionService.gameSessionActive = true;
    _autoSave();
  }

  /// Load a previously saved in-progress game from local storage.
  Future<bool> loadSavedGame() async {
    final saved = await PersistenceService.loadCurrentGame();
    if (saved == null) return false;
    _recorder.clear();
    _undoStack.clear();
    _redoStack.clear();
    final board = PersistenceService.restoreBoard(saved);
    state = GameState(
      board: board,
      difficulty: saved.difficulty,
      elapsed: saved.elapsed,
      conflicts: SudokuValidator.findConflicts(board),
      initialBoard: saved.initialBoard,
      isImported: saved.isImported,
    );
    SessionService.gameSessionActive = true;
    return true;
  }

  /// Check if a saved game exists in storage.
  Future<SavedGame?> checkSavedGame() =>
      PersistenceService.loadCurrentGame();

  void _autoSave() {
    if (state.initialBoard.isEmpty) return;
    PersistenceService.saveCurrentGame(
      board: state.board,
      difficulty: state.difficulty,
      elapsed: state.elapsed,
      initialBoard: state.initialBoard,
      isImported: state.isImported,
    );
  }

  void _saveToHistoryAndClearCurrent() {
    final record = PersistenceService.buildRecord(
      board: state.board,
      difficulty: state.difficulty,
      elapsed: state.elapsed,
      isComplete: state.isComplete,
      initialBoard: state.initialBoard,
      isImported: state.isImported,
    );
    PersistenceService.saveToHistory(record);
    if (state.isComplete) {
      PersistenceService.recordCompletion(
        difficulty: state.difficulty,
        elapsed: state.elapsed,
        date: DateTime.now(),
      );
      PersistenceService.clearCurrentGame();
    }
  }

  void selectCell(int row, int col, {bool toggle = false, bool addToSelection = false}) {
    // In highlighter mode: tapping a cell immediately paints it with the
    // current colour (or the X-stamp when highlightColorIndex == -1).
    if (state.entryMode == EntryMode.highlighter) {
      _paintHighlight(row, col, saveUndo: true);
      return;
    }

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
    state = state.copyWith(selectedCells: newSelection, clearPinnedDigit: true);
  }

  /// Always adds [row],[col] to the current selection (never removes).
  /// Used during drag-select so cells only accumulate, never toggle off.
  void addCellToSelection(int row, int col) {
    // In highlighter mode: paint the cell immediately as the user drags.
    // No undo snapshot here — the snapshot was saved when the drag began
    // (via beginHighlightDrag called from the grid's onPanStart handler).
    if (state.entryMode == EntryMode.highlighter) {
      _paintHighlight(row, col, saveUndo: false);
      return;
    }
    final newSelection = Set<(int, int)>.from(state.selectedCells)..add((row, col));
    state = state.copyWith(selectedCells: newSelection, clearPinnedDigit: true);
  }

  /// Called at the start of a paint-drag gesture in highlight mode so that
  /// the entire drag can be undone in a single undo step.
  void beginHighlightDrag() {
    _saveUndoSnapshot();
    _redoStack.clear();
  }

  /// Applies the current [highlightColorIndex] to the cell at ([row], [col]).
  ///
  /// Tapping a cell that already carries the same colour clears it (toggle
  /// off), making it easy to remove a highlight without switching modes.
  ///
  /// When [saveUndo] is true an undo snapshot is pushed before the change
  /// (used for individual taps). During a drag [beginHighlightDrag] already
  /// saved the snapshot, so subsequent cells pass [saveUndo] = false.
  void _paintHighlight(int row, int col, {required bool saveUndo}) {
    final newBoard = state.board.copy();
    final cell = newBoard.cells[row][col];
    final colorIdx = state.highlightColorIndex;
    // Toggle: tapping the same colour a second time removes it.
    cell.highlightColor = (cell.highlightColor == colorIdx) ? null : colorIdx;
    if (saveUndo) {
      _saveUndoSnapshot();
      _redoStack.clear();
    }
    _recorder.record(MoveRecord(
      type: MoveType.highlight,
      timestamp: DateTime.now(),
      cells: [(row, col)],
      value: colorIdx,
    ));
    // Clear selection so the painted colour is immediately visible
    // (the selection teal overlay would otherwise obscure the highlight).
    state = state.copyWith(
      board: newBoard,
      selectedCells: const {},
      clearPinnedDigit: true,
    );
    _autoSave();
  }

  void toggleMultiSelect() {
    state = state.copyWith(multiSelectMode: !state.multiSelectMode);
  }

  void deselectAll() {
    state = state.copyWith(selectedCells: const {}, clearPinnedDigit: true);
  }

  void setEntryMode(EntryMode mode) {
    state = state.copyWith(entryMode: mode);
  }

  /// Sets entry mode and multi-select state in one atomic update.
  /// Switching from multi-select to single-select deselects all cells only when
  /// more than one cell is selected; a single selected cell is preserved.
  void setEntryModeAndMulti(EntryMode mode, bool multi) {
    final wasMulti = state.multiSelectMode;
    final selectedCells = (wasMulti && !multi && state.selectedCells.length > 1)
        ? const <(int, int)>{}
        : state.selectedCells;
    state = state.copyWith(
      entryMode: mode,
      multiSelectMode: multi,
      selectedCells: selectedCells,
    );
  }

  void setHighlightColor(int index) {
    state = state.copyWith(highlightColorIndex: index);
  }

  /// Long-press a digit button for ~1 s:
  /// • If the current selection contains writable cells (non-given, digit == null):
  ///   place [digit] in each such cell, skipping any where it would conflict.
  /// • Otherwise (no selection or all selected are givens):
  ///   pin [digit] so every board cell carrying that value is tinted.
  void longPressDigit(int digit) {
    final sel = state.selectedCells;
    final writableCells = sel
        .where((pos) {
          final cell = state.board.cellAt(pos.$1, pos.$2);
          return !cell.isGiven && cell.digit == null;
        })
        .toList();

    if (writableCells.isEmpty) {
      // No writable cells selected — show same-value highlight for this digit.
      state = state.copyWith(
        pinnedDigit: digit,
        selectedCells: const {},
      );
      return;
    }

    // Write digit to every writable cell that has no conflict.
    final newBoard = state.board.copy();
    final affected = <(int, int)>[];
    for (final (r, c) in writableCells) {
      if (SudokuValidator.isValidPlacement(newBoard, r, c, digit)) {
        final cell = newBoard.cells[r][c];
        cell.digit = digit;
        cell.cornerNotes.clear();
        cell.centreNotes.clear();
        _removeCandidateFromPeers(newBoard, r, c, digit);
        affected.add((r, c));
      }
    }
    if (affected.isEmpty) return;
    _saveUndoSnapshot();
    _redoStack.clear();
    _recorder.record(MoveRecord(
      type: MoveType.placeDigit,
      timestamp: DateTime.now(),
      cells: affected,
      value: digit,
    ));
    final conflicts = SudokuValidator.findConflicts(newBoard);
    state = state.copyWith(
      board: newBoard,
      conflicts: conflicts,
      isComplete: newBoard.isSolved && conflicts.isEmpty,
    );
    _autoSave();
    if (state.isComplete) _saveToHistoryAndClearCurrent();
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
          _removeCandidateFromPeers(newBoard, r, c, digit);
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
        _autoSave();
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
    _autoSave();
    if (complete) _saveToHistoryAndClearCurrent();
  }

  /// Removes [digit] from the corner and centre notes of every cell that
  /// shares a row, column, or 3×3 box with ([row], [col]).
  void _removeCandidateFromPeers(SudokuBoard board, int row, int col, int digit) {
    for (int c = 0; c < 9; c++) {
      if (c != col) {
        board.cells[row][c].cornerNotes.remove(digit);
        board.cells[row][c].centreNotes.remove(digit);
      }
    }
    for (int r = 0; r < 9; r++) {
      if (r != row) {
        board.cells[r][col].cornerNotes.remove(digit);
        board.cells[r][col].centreNotes.remove(digit);
      }
    }
    final boxR = (row ~/ 3) * 3;
    final boxC = (col ~/ 3) * 3;
    for (int r = boxR; r < boxR + 3; r++) {
      for (int c = boxC; c < boxC + 3; c++) {
        if (r != row || c != col) {
          board.cells[r][c].cornerNotes.remove(digit);
          board.cells[r][c].centreNotes.remove(digit);
        }
      }
    }
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
    _autoSave();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(state.board);
    final prevBoard = _undoStack.removeLast();
    final conflicts = SudokuValidator.findConflicts(prevBoard);
    state = state.copyWith(board: prevBoard, conflicts: conflicts, isComplete: false);
    _autoSave();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(state.board);
    final nextBoard = _redoStack.removeLast();
    final conflicts = SudokuValidator.findConflicts(nextBoard);
    final complete = nextBoard.isSolved && conflicts.isEmpty;
    state = state.copyWith(board: nextBoard, conflicts: conflicts, isComplete: complete);
    _autoSave();
    if (complete) _saveToHistoryAndClearCurrent();
  }

  void updateTimer(Duration elapsed) {
    state = state.copyWith(elapsed: elapsed);
    // Periodically persist elapsed time (every 30 s, only when a game is
    // active and the user hasn't moved recently — board mutations already
    // trigger _autoSave() so this only catches idle "thinking" time).
    if (state.initialBoard.isNotEmpty &&
        !state.isComplete &&
        elapsed.inSeconds % 30 == 0) {
      _autoSave();
    }
  }

  void toggleConflicts() {
    state = state.copyWith(showConflicts: !state.showConflicts);
  }

  void toggleAutoCandidates() {
    state = state.copyWith(autoCandidates: !state.autoCandidates);
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void _saveUndoSnapshot() {
    _undoStack.add(state.board.copy());
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
