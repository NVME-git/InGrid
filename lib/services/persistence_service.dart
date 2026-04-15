/// Handles all local-storage persistence for InGrid using shared_preferences.
///
/// Data stored:
///   • current_game  – full board + notes + elapsed, overwritten on every move
///   • game_history  – JSON list of [GameRecord] sorted newest-first
///   • game_stats    – per-difficulty list of completion times (seconds)

library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/engine/engine.dart';

// ──────────────────────────────────────────────────────────────────────────────
// GameRecord — one entry in the history list
// ──────────────────────────────────────────────────────────────────────────────

class GameRecord {
  final String id;
  final Difficulty difficulty;
  final DateTime date;
  final Duration elapsed;
  final bool isComplete;

  /// 81-char string of the original givens (0 = empty cell, row-major order).
  final String initialBoard;

  /// 81-char string of the final/current board state (0 = empty).
  final String finalBoard;

  /// True when this game was imported via a string or the manual grid.
  final bool isImported;

  const GameRecord({
    required this.id,
    required this.difficulty,
    required this.date,
    required this.elapsed,
    required this.isComplete,
    required this.initialBoard,
    required this.finalBoard,
    this.isImported = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'difficulty': difficulty.name,
        'date_ms': date.millisecondsSinceEpoch,
        'elapsed_ms': elapsed.inMilliseconds,
        'is_complete': isComplete,
        'initial_board': initialBoard,
        'final_board': finalBoard,
        'is_imported': isImported,
      };

  factory GameRecord.fromJson(Map<String, dynamic> j) => GameRecord(
        id: j['id'] as String,
        difficulty: Difficulty.values.firstWhere(
          (d) => d.name == j['difficulty'],
          orElse: () => Difficulty.medium,
        ),
        date: DateTime.fromMillisecondsSinceEpoch(j['date_ms'] as int),
        elapsed: Duration(milliseconds: j['elapsed_ms'] as int),
        isComplete: j['is_complete'] as bool,
        initialBoard: j['initial_board'] as String,
        finalBoard: j['final_board'] as String,
        isImported: j['is_imported'] as bool? ?? false,
      );

  /// Returns the board state as a human-readable 81-char string.
  String toShareString() => finalBoard;
}

// ──────────────────────────────────────────────────────────────────────────────
// SavedGame — the in-progress game snapshot
// ──────────────────────────────────────────────────────────────────────────────

class SavedGame {
  final Difficulty difficulty;
  final Duration elapsed;
  final String initialBoard; // 81-char givens string
  final List<Map<String, dynamic>> cells; // 81 cell objects
  final bool isImported;

  const SavedGame({
    required this.difficulty,
    required this.elapsed,
    required this.initialBoard,
    required this.cells,
    this.isImported = false,
  });

  Map<String, dynamic> toJson() => {
        'version': 1,
        'difficulty': difficulty.name,
        'elapsed_ms': elapsed.inMilliseconds,
        'initial_board': initialBoard,
        'cells': cells,
        'is_imported': isImported,
      };

  factory SavedGame.fromJson(Map<String, dynamic> j) => SavedGame(
        difficulty: Difficulty.values.firstWhere(
          (d) => d.name == j['difficulty'],
          orElse: () => Difficulty.medium,
        ),
        elapsed: Duration(milliseconds: j['elapsed_ms'] as int),
        initialBoard: j['initial_board'] as String,
        cells: (j['cells'] as List).cast<Map<String, dynamic>>(),
        isImported: j['is_imported'] as bool? ?? false,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// PersistenceService
// ──────────────────────────────────────────────────────────────────────────────

class PersistenceService {
  static const _currentGameKey = 'current_game_v1';
  static const _historyKey = 'game_history_v1';
  static const _statsKey = 'game_stats_v1';
  static const _pwaInstallDismissedKey = 'pwa_install_banner_dismissed';

  // ── Board serialisation helpers ──────────────────────────────────────────

  static List<Map<String, dynamic>> _boardToCells(SudokuBoard board) {
    final result = <Map<String, dynamic>>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = board.cells[r][c];
        result.add({
          'g': cell.isGiven ? 1 : 0,
          'd': cell.digit ?? 0,
          'cn': cell.cornerNotes.toList()..sort(),
          'en': cell.centreNotes.toList()..sort(),
          'hc': cell.highlightColor ?? -99,
        });
      }
    }
    return result;
  }

  static SudokuBoard _cellsToBoard(List<Map<String, dynamic>> cells) {
    final board = SudokuBoard(
      cells: List.generate(9, (_) => List.generate(9, (_) => SudokuCell())),
    );
    for (int i = 0; i < 81; i++) {
      final r = i ~/ 9;
      final c = i % 9;
      final j = cells[i];
      final isGiven = (j['g'] as int) == 1;
      final digit = (j['d'] as int) == 0 ? null : j['d'] as int;
      final cell = SudokuCell(isGiven: isGiven, digit: digit);
      cell.cornerNotes.addAll((j['cn'] as List).cast<int>());
      cell.centreNotes.addAll((j['en'] as List).cast<int>());
      final hc = j['hc'] as int;
      cell.highlightColor = hc == -99 ? null : hc;
      board.cells[r][c] = cell;
    }
    return board;
  }

  /// 81-char string of given digits only (0 = empty / non-given).
  static String _boardToGivensString(SudokuBoard board) {
    final buf = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = board.cells[r][c];
        buf.write(cell.isGiven ? (cell.digit ?? 0) : 0);
      }
    }
    return buf.toString();
  }

  /// 81-char string of all placed digits (0 = empty).
  static String _boardToDigitString(SudokuBoard board) {
    final buf = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        buf.write(board.cells[r][c].digit ?? 0);
      }
    }
    return buf.toString();
  }

  // ── Current game ─────────────────────────────────────────────────────────

  /// Saves the active in-progress game state to localStorage.
  static Future<void> saveCurrentGame({
    required SudokuBoard board,
    required Difficulty difficulty,
    required Duration elapsed,
    required String initialBoard,
    bool isImported = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = SavedGame(
        difficulty: difficulty,
        elapsed: elapsed,
        initialBoard: initialBoard,
        cells: _boardToCells(board),
        isImported: isImported,
      );
      await prefs.setString(_currentGameKey, jsonEncode(saved.toJson()));
    } catch (_) {
      // Never crash the game loop due to persistence errors.
    }
  }

  /// Loads the previously saved in-progress game, or null if none.
  static Future<SavedGame?> loadCurrentGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentGameKey);
      if (raw == null) return null;
      return SavedGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Restores a SavedGame back into a SudokuBoard.
  static SudokuBoard restoreBoard(SavedGame saved) =>
      _cellsToBoard(saved.cells);

  /// Removes the current game save (called when game completes or is abandoned).
  static Future<void> clearCurrentGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentGameKey);
    } catch (_) {}
  }

  // ── Game history ─────────────────────────────────────────────────────────

  /// Appends a record to history (newest first, max 100 entries).
  static Future<void> saveToHistory(GameRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadHistory();
      final updated = [record, ...existing];
      if (updated.length > 100) updated.removeRange(100, updated.length);
      await prefs.setString(
        _historyKey,
        jsonEncode(updated.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }

  static Future<List<GameRecord>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(GameRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  /// Records a completion time for the given difficulty.
  static Future<void> recordCompletion({
    required Difficulty difficulty,
    required Duration elapsed,
    required DateTime date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = await loadStats();
      stats.putIfAbsent(difficulty.name, () => <Map<String, dynamic>>[]);
      stats[difficulty.name]!.add({
        'secs': elapsed.inSeconds,
        'date_ms': date.millisecondsSinceEpoch,
      });
      await prefs.setString(_statsKey, jsonEncode(stats));
    } catch (_) {}
  }

  /// Returns stats as { "easy": [{"secs":200,"date_ms":...}, ...], ... }.
  static Future<Map<String, List<Map<String, dynamic>>>> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_statsKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(
            k,
            (v as List).cast<Map<String, dynamic>>(),
          ));
    } catch (_) {
      return {};
    }
  }

  // ── PWA install banner ───────────────────────────────────────────────────

  /// Returns true when the user has previously dismissed the install banner.
  static Future<bool> isPwaInstallBannerDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pwaInstallDismissedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Persists the user's choice to dismiss the install banner permanently.
  static Future<void> dismissPwaInstallBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pwaInstallDismissedKey, true);
    } catch (_) {}
  }

  // ── Helpers for external callers ─────────────────────────────────────────

  /// Builds a GameRecord from the current board when the game ends / is saved.
  static GameRecord buildRecord({
    required SudokuBoard board,
    required Difficulty difficulty,
    required Duration elapsed,
    required bool isComplete,
    required String initialBoard,
    bool isImported = false,
  }) =>
      GameRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        difficulty: difficulty,
        date: DateTime.now(),
        elapsed: elapsed,
        isComplete: isComplete,
        initialBoard: initialBoard,
        finalBoard: _boardToDigitString(board),
        isImported: isImported,
      );

  /// Converts a board to the 81-char givens string (for first-time saves).
  static String boardToGivensString(SudokuBoard board) =>
      _boardToGivensString(board);

  /// Converts an 81-char digit string (0 = empty, 1-9 = given) to a SudokuBoard.
  static SudokuBoard boardFromString(String s) {
    final board = SudokuBoard(
      cells: List.generate(9, (_) => List.generate(9, (_) => SudokuCell())),
    );
    for (int i = 0; i < 81 && i < s.length; i++) {
      final digit = int.tryParse(s[i]) ?? 0;
      if (digit != 0) {
        board.cells[i ~/ 9][i % 9] = SudokuCell(isGiven: true, digit: digit);
      }
    }
    return board;
  }

  /// Updates the difficulty of a history record by id.
  static Future<void> updateRecordDifficulty(
      String id, Difficulty newDifficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await loadHistory();
      final updated = records.map((r) {
        if (r.id != id) return r;
        return GameRecord(
          id: r.id,
          difficulty: newDifficulty,
          date: r.date,
          elapsed: r.elapsed,
          isComplete: r.isComplete,
          initialBoard: r.initialBoard,
          finalBoard: r.finalBoard,
          isImported: r.isImported,
        );
      }).toList();
      await prefs.setString(
        _historyKey,
        jsonEncode(updated.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }
}
