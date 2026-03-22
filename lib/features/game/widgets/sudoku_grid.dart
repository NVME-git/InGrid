import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_state.dart';
import '../../../core/engine/engine.dart';

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
          border: Border.all(color: Colors.white70, width: 2),
        ),
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
                    ref.read(gameProvider.notifier).selectCell(row, col, addToSelection: true);
                  }
                },
              );
            },
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

    // Border styling - thicker on box edges
    final borderLeft = (col % 3 == 0) ? 1.5 : 0.5;
    final borderTop = (row % 3 == 0) ? 1.5 : 0.5;
    final borderRight = (col == 8) ? 0.0 : (col % 3 == 2) ? 0.0 : 0.0;
    final borderBottom = (row == 8) ? 0.0 : (row % 3 == 2) ? 0.0 : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) => onDragEnter(),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: Colors.white30, width: borderLeft),
              top: BorderSide(color: Colors.white30, width: borderTop),
              right: BorderSide(color: Colors.white30, width: borderRight),
              bottom: BorderSide(color: Colors.white30, width: borderBottom),
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
    // 3x3 grid positions for corner notes 1-9
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
