// Board cell data model
class SudokuCell {
  final bool isGiven;
  int? digit; // 1-9 or null
  final Set<int> cornerNotes = {};
  final Set<int> centreNotes = {};
  int? highlightColor; // 0-8 for colors, -1 for X-stamp

  SudokuCell({this.isGiven = false, this.digit});

  SudokuCell copyWith({bool? isGiven, int? digit, Set<int>? cornerNotes, Set<int>? centreNotes, int? highlightColor}) {
    final cell = SudokuCell(isGiven: isGiven ?? this.isGiven, digit: digit ?? this.digit);
    cell.cornerNotes.addAll(cornerNotes ?? this.cornerNotes);
    cell.centreNotes.addAll(centreNotes ?? this.centreNotes);
    cell.highlightColor = highlightColor ?? this.highlightColor;
    return cell;
  }
}

// Immutable board state  
class SudokuBoard {
  final List<List<SudokuCell>> cells; // [row][col]

  const SudokuBoard({required this.cells});

  factory SudokuBoard.empty() {
    return SudokuBoard(
      cells: List.generate(9, (_) => List.generate(9, (_) => SudokuCell())),
    );
  }

  SudokuCell cellAt(int row, int col) => cells[row][col];

  // Returns a deep copy
  SudokuBoard copy() {
    return SudokuBoard(
      cells: cells.map((row) => row.map((cell) => cell.copyWith()).toList()).toList(),
    );
  }

  bool get isSolved {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (cells[r][c].digit == null) return false;
      }
    }
    return true;
  }
}
