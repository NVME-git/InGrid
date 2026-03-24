enum MoveType { placeDigit, addCornerNote, addCentreNote, erase, hint, highlight }

class MoveRecord {
  final MoveType type;
  final DateTime timestamp;
  final List<(int, int)> cells;
  final int? value; // digit, note digit, or highlight color

  const MoveRecord({
    required this.type,
    required this.timestamp,
    required this.cells,
    this.value,
  });
}

class MoveRecorder {
  final List<MoveRecord> _history = [];
  int _cursor = 0; // points to the next slot (undo/redo)

  List<MoveRecord> get history => List.unmodifiable(_history.sublist(0, _cursor));

  void record(MoveRecord move) {
    // Truncate redo history
    _history.removeRange(_cursor, _history.length);
    _history.add(move);
    _cursor++;
  }

  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _history.length;

  MoveRecord? undo() {
    if (!canUndo) return null;
    _cursor--;
    return _history[_cursor];
  }

  MoveRecord? redo() {
    if (!canRedo) return null;
    final move = _history[_cursor];
    _cursor++;
    return move;
  }

  void clear() {
    _history.clear();
    _cursor = 0;
  }
}
