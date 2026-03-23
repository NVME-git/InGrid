import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_state.dart';
import '../../../core/engine/engine.dart';

// Visual constants
const _kBoxBorder = 2.5; // thick border between 3×3 boxes
const _kCellBorder = 0.5; // thin border between individual cells
const _kBoxColor = Color(0xFFCCCCCC); // bright for box separators
const _kCellColor = Color(0x44FFFFFF); // dim for inner cell lines

// Background tint colours (priority: selected > conflict > flash > sameValue > highlight > peer)
const _kSelectedAlpha = 0.35;
const _kSameValueAlpha = 0.22;
const _kPeerAlpha = 0.10;

class SudokuGrid extends ConsumerStatefulWidget {
  const SudokuGrid({super.key});

  @override
  ConsumerState<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends ConsumerState<SudokuGrid> {
  bool _isDragging = false;
  final _gridKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final board = game.board;
    final selected = game.selectedCells;
    final conflicts = game.showConflicts ? game.conflicts : <(int, int)>{};

    // ── Compute peer cells (same row / col / box as any selected cell) ──────
    final Set<(int, int)> peerCells = {};
    final Set<int> selectedDigits = {};
    for (final (sr, sc) in selected) {
      final d = board.cellAt(sr, sc).digit;
      if (d != null) selectedDigits.add(d);
      for (int c = 0; c < 9; c++) {
        if (c != sc) peerCells.add((sr, c));
      }
      for (int r = 0; r < 9; r++) {
        if (r != sr) peerCells.add((r, sc));
      }
      final boxR = (sr ~/ 3) * 3;
      final boxC = (sc ~/ 3) * 3;
      for (int r = boxR; r < boxR + 3; r++) {
        for (int c = boxC; c < boxC + 3; c++) {
          if (r != sr || c != sc) peerCells.add((r, c));
        }
      }
    }

    // ── Cells with the same digit as any selected cell (or pinned digit) ────
    final Set<(int, int)> sameValueCells = {};
    // If no cells are selected but a digit is pinned (long-press highlight),
    // treat the pinned digit as the "selected" digit.
    final effectiveDigits = selectedDigits.isNotEmpty
        ? selectedDigits
        : (game.pinnedDigit != null ? {game.pinnedDigit!} : <int>{});
    if (effectiveDigits.isNotEmpty) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!selected.contains((r, c))) {
            final d = board.cellAt(r, c).digit;
            if (d != null && effectiveDigits.contains(d)) {
              sameValueCells.add((r, c));
            }
          }
        }
      }
    }

    // ── When a digit is pinned via long-press, also highlight peers of every
    //    matching-value cell so unhighlighted cells reveal candidate positions.
    if (game.pinnedDigit != null && selected.isEmpty) {
      for (final (sr, sc) in sameValueCells) {
        for (int c = 0; c < 9; c++) {
          if (c != sc) peerCells.add((sr, c));
        }
        for (int r = 0; r < 9; r++) {
          if (r != sr) peerCells.add((r, sc));
        }
        final boxR = (sr ~/ 3) * 3;
        final boxC = (sc ~/ 3) * 3;
        for (int r = boxR; r < boxR + 3; r++) {
          for (int c = boxC; c < boxC + 3; c++) {
            if (r != sr || c != sc) peerCells.add((r, c));
          }
        }
      }
    }

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
            key: _gridKey,
            onPanStart: (details) {
              _isDragging = true;
              // Select the initial cell additively so drag always accumulates.
              final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
              if (rb != null) {
                final size = rb.size;
                final row =
                    ((details.localPosition.dy / size.height) * 9).clamp(0.0, 8.99).toInt();
                final col =
                    ((details.localPosition.dx / size.width) * 9).clamp(0.0, 8.99).toInt();
                ref.read(gameProvider.notifier).addCellToSelection(row, col);
              }
            },
            onPanEnd: (_) => _isDragging = false,
            onPanCancel: () => _isDragging = false,
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
                final isFlashConflict = game.flashConflictCells.contains((row, col));
                final isFlashNoteAttempt = game.flashNoteCells.contains((row, col));

                // Compute auto-candidate notes: shown for empty cells with no user
                // notes when auto-candidates mode is active.
                Set<int>? autoCandidateNotes;
                if (game.autoCandidates &&
                    cell.digit == null &&
                    cell.cornerNotes.isEmpty &&
                    cell.centreNotes.isEmpty) {
                  autoCandidateNotes = {};
                  for (int d = 1; d <= 9; d++) {
                    if (SudokuValidator.isValidPlacement(board, row, col, d)) {
                      autoCandidateNotes.add(d);
                    }
                  }
                }

                return _SudokuCell(
                  cell: cell,
                  row: row,
                  col: col,
                  isSelected: isSelected,
                  hasConflict: hasConflict,
                  isPeer: !isSelected && peerCells.contains((row, col)),
                  isSameValue: sameValueCells.contains((row, col)),
                  isFlashConflict: isFlashConflict,
                  isFlashNoteAttempt: isFlashNoteAttempt,
                  flashNoteDigit: game.flashNoteDigit,
                  flashNoteMode: game.flashNoteMode,
                  autoCandidateNotes: autoCandidateNotes,
                  onTap: () {
                    ref.read(gameProvider.notifier).selectCell(row, col);
                  },
                  onDragEnter: () {
                    if (_isDragging) {
                      ref
                          .read(gameProvider.notifier)
                          .addCellToSelection(row, col);
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
  final bool isPeer;
  final bool isSameValue;
  final bool isFlashConflict;
  final bool isFlashNoteAttempt;
  final int? flashNoteDigit;
  final EntryMode? flashNoteMode;
  /// Non-null when auto-candidates mode is on and cell is empty with no user notes.
  final Set<int>? autoCandidateNotes;
  final VoidCallback onTap;
  final VoidCallback onDragEnter;

  const _SudokuCell({
    required this.cell,
    required this.row,
    required this.col,
    required this.isSelected,
    required this.hasConflict,
    required this.isPeer,
    required this.isSameValue,
    required this.isFlashConflict,
    required this.isFlashNoteAttempt,
    required this.flashNoteDigit,
    required this.flashNoteMode,
    this.autoCandidateNotes,
    required this.onTap,
    required this.onDragEnter,
  });

  /// Left border width: 0 for first column, box-width at box edges, thin elsewhere.
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
    // Priority (highest → lowest):
    //   selected > conflict/flash-conflict > flash-note-attempt >
    //   same-value > user-highlight > peer
    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = const Color(0xFF0D9488).withValues(alpha: _kSelectedAlpha);
    } else if (isFlashConflict) {
      bgColor = Colors.red.withValues(alpha: 0.45);
    } else if (hasConflict) {
      bgColor = Colors.red.withValues(alpha: 0.25);
    } else if (isFlashNoteAttempt) {
      bgColor = Colors.orange.withValues(alpha: 0.30);
    } else if (isSameValue) {
      bgColor = const Color(0xFF0D9488).withValues(alpha: _kSameValueAlpha);
    } else if (cell.highlightColor != null && cell.highlightColor! >= 0) {
      final hc = cell.highlightColor!;
      if (hc < kHighlightColors.length) {
        bgColor = Color(kHighlightColors[hc]).withValues(alpha: 0.4);
      }
    } else if (isPeer) {
      bgColor = const Color(0xFF0D9488).withValues(alpha: _kPeerAlpha);
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) => onDragEnter(),
        child: LayoutBuilder(builder: (ctx, constraints) {
          final cellSize = constraints.maxWidth;
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                left: BorderSide(color: _leftC(col), width: _leftW(col)),
                top: BorderSide(color: _topC(row), width: _topW(row)),
              ),
            ),
            child: _buildCellContent(cellSize),
          );
        }),
      ),
    );
  }

  Widget _buildCellContent(double cellSize) {
    // Corner-note font: ~21% of cell width (each note sits in a 1/3-width slot).
    // Centre-note font: ~25% of cell width.
    // Clamp to sane min/max so tiny cells are still readable.
    final cornerFontSize = (cellSize * 0.21).clamp(8.0, 14.0);
    final centreFontSize = (cellSize * 0.25).clamp(9.0, 16.0);

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

    final hasUserNotes = cell.cornerNotes.isNotEmpty || cell.centreNotes.isNotEmpty;
    final hasAutoNotes = autoCandidateNotes?.isNotEmpty == true;
    final hasNotes = hasUserNotes || hasAutoNotes;

    if (hasNotes || isFlashNoteAttempt) {
      return Stack(
        children: [
          if (cell.cornerNotes.isNotEmpty)
            _CornerNotes(notes: cell.cornerNotes, fontSize: cornerFontSize)
          else if (hasAutoNotes)
            _CornerNotes(
                notes: autoCandidateNotes!,
                fontSize: cornerFontSize,
                textColor: Colors.white30),
          if (cell.centreNotes.isNotEmpty)
            Center(
              child: Text(
                (cell.centreNotes.toList()..sort()).join(),
                style: TextStyle(fontSize: centreFontSize, color: Colors.white70),
              ),
            ),
          // Flash: briefly show the rejected digit in red
          if (isFlashNoteAttempt && flashNoteDigit != null)
            _FlashNoteOverlay(
                digit: flashNoteDigit!,
                mode: flashNoteMode,
                cornerFontSize: cornerFontSize,
                centreFontSize: centreFontSize),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

/// Briefly displays a rejected note digit in red.
class _FlashNoteOverlay extends StatelessWidget {
  final int digit;
  final EntryMode? mode;
  final double cornerFontSize;
  final double centreFontSize;

  const _FlashNoteOverlay({
    required this.digit,
    this.mode,
    this.cornerFontSize = 8,
    this.centreFontSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == EntryMode.cornerNote) {
      // Show digit in its corner-note grid position, in red.
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        itemBuilder: (_, i) {
          final d = i + 1;
          return Center(
            child: Text(
              d == digit ? '$d' : '',
              style: TextStyle(fontSize: cornerFontSize, color: Colors.red),
            ),
          );
        },
      );
    }
    // Centre note style
    return Center(
      child: Text(
        '$digit',
        style: TextStyle(fontSize: centreFontSize, color: Colors.red),
      ),
    );
  }
}

class _CornerNotes extends StatelessWidget {
  final Set<int> notes;
  final Color textColor;
  final double fontSize;
  const _CornerNotes({
    required this.notes,
    this.textColor = Colors.white54,
    this.fontSize = 8,
  });

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
            style: TextStyle(fontSize: fontSize, color: textColor),
          ),
        );
      },
    );
  }
}
