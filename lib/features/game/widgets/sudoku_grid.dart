import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_state.dart';
import '../../../core/engine/engine.dart';

// Visual constants
const _kBoxBorder = 2.5; // thick border between 3×3 boxes
const _kCellBorder = 0.5; // thin border between individual cells
const _kBoxColor = Color(0xFFCCCCCC); // bright for box separators
const _kCellColor = Color(0x44FFFFFF); // dim for inner cell lines

class SudokuGrid extends ConsumerStatefulWidget {
  const SudokuGrid({super.key});

  @override
  ConsumerState<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends ConsumerState<SudokuGrid> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final board = game.board;
    final selected = game.selectedCells;
    final conflicts = game.showConflicts ? game.conflicts : <(int, int)>{};

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _kBoxColor, width: _kBoxBorder),
          borderRadius: BorderRadius.circular(2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: GestureDetector(
            onPanStart: (_) => _isDragging = true,
            onPanEnd: (_) => _isDragging = false,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                final row = index ~/ 9;
                final col = index % 9;
                final cell = board.cellAt(row, col);
                final isSelected = selected.contains((row, col));
                final hasConflict = conflicts.contains((row, col));

                return _SudokuCell(
                  cell: cell,
                  row: row,
                  col: col,
                  isSelected: isSelected,
                  hasConflict: hasConflict,
                  onTap: () {
                    ref.read(gameProvider.notifier).selectCell(row, col);
                  },
                  onDragEnter: () {
                    if (_isDragging) {
                      ref
                          .read(gameProvider.notifier)
                          .selectCell(row, col, addToSelection: true);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SudokuCell extends StatelessWidget {
  final SudokuCell cell;
  final int row;
  final int col;
  final bool isSelected;
  final bool hasConflict;
  final VoidCallback onTap;
  final VoidCallback onDragEnter;

  const _SudokuCell({
    required this.cell,
    required this.row,
    required this.col,
    required this.isSelected,
    required this.hasConflict,
    required this.onTap,
    required this.onDragEnter,
  });

  /// Compute the border width for a given edge.
  /// A box-edge border is _kBoxBorder; an inner-cell border is _kCellBorder.
  /// The outermost grid edge is handled by the parent container, so cells
  /// on the outer edge get no border on that side (0).
  static double _leftW(int col) {
    if (col == 0) return 0;
    if (col % 3 == 0) return _kBoxBorder;
    return _kCellBorder;
  }

  static double _topW(int row) {
    if (row == 0) return 0;
    if (row % 3 == 0) return _kBoxBorder;
    return _kCellBorder;
  }

  static Color _leftC(int col) => col % 3 == 0 ? _kBoxColor : _kCellColor;
  static Color _topC(int row) => row % 3 == 0 ? _kBoxColor : _kCellColor;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = const Color(0xFF0D9488).withValues(alpha: 0.35);
    } else if (hasConflict) {
      bgColor = Colors.red.withValues(alpha: 0.25);
    } else if (cell.highlightColor != null && cell.highlightColor! >= 0) {
      final hc = cell.highlightColor!;
      if (hc < kHighlightColors.length) {
        bgColor = Color(kHighlightColors[hc]).withValues(alpha: 0.4);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) => onDragEnter(),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: _leftC(col), width: _leftW(col)),
              top: BorderSide(color: _topC(row), width: _topW(row)),
            ),
          ),
          child: _buildCellContent(),
        ),
      ),
    );
  }

  Widget _buildCellContent() {
    if (cell.digit != null) {
      return Center(
        child: Text(
          '${cell.digit}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: cell.isGiven ? FontWeight.bold : FontWeight.normal,
            color: cell.isGiven ? Colors.white : const Color(0xFF0D9488),
          ),
        ),
      );
    }

    // Show X stamp
    if (cell.highlightColor == -1) {
      return const Center(
        child: Text('✕', style: TextStyle(color: Colors.red, fontSize: 18)),
      );
    }

    // Show notes
    if (cell.cornerNotes.isNotEmpty || cell.centreNotes.isNotEmpty) {
      return Stack(
        children: [
          if (cell.cornerNotes.isNotEmpty)
            _CornerNotes(notes: cell.cornerNotes),
          if (cell.centreNotes.isNotEmpty)
            Center(
              child: Text(
                (cell.centreNotes.toList()..sort()).join(),
                style: const TextStyle(fontSize: 7, color: Colors.white70),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _CornerNotes extends StatelessWidget {
  final Set<int> notes;
  const _CornerNotes({required this.notes});

  @override
  Widget build(BuildContext context) {
    // 3×3 grid positions for corner notes 1-9
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: 9,
      itemBuilder: (_, i) {
        final digit = i + 1;
        return Center(
          child: Text(
            notes.contains(digit) ? '$digit' : '',
            style: const TextStyle(fontSize: 6, color: Colors.white54),
          ),
        );
      },
    );
  }
}
