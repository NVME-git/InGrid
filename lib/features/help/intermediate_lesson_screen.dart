import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D9488);
const _bg = Color(0xFF1A1A2E);
const _ts = TextStyle(color: Colors.white70, fontSize: 13, height: 1.5);
const _ths = TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.bold);
const _subhs = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600);

class IntermediateLessonScreen extends StatelessWidget {
  const IntermediateLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 80,
        leading: GestureDetector(
          onTap: () => context.go('/'),
          child: const Center(
            child: Text(
              'InGrid',
              style: TextStyle(
                color: _teal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        title: const Text(
          'Intermediate Techniques',
          style: TextStyle(color: _teal, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.trending_up, color: _teal),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // ── Introduction ───────────────────────────────────────────
              Text('Level Up Your Skills', style: _ths),
              SizedBox(height: 8),
              Text(
                'These techniques will help you solve Hard puzzles and prepare you for '
                'Advanced strategies. They involve looking at patterns across multiple cells.',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Naked Pairs ────────────────────────────────────────────
              Text('1. Naked Pairs', style: _ths),
              SizedBox(height: 4),
              Text(
                'When two cells in the same row, column, or box can only contain the same '
                'two candidates, those digits can\'t appear anywhere else in that unit.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Example:\n'
                '• Cells A and B both have candidates {3,7}\n'
                '• They\'re in the same row\n'
                '• Remove 3 and 7 from all other cells in that row',
                style: _ts,
              ),
              SizedBox(height: 4),
              _TechniqueNote(
                note: 'Naked Triples work the same way with three cells and three digits.',
              ),
              SizedBox(height: 8),
              _SudokuGrid(
                title: 'Naked Pair Example (Row 1)',
                grid: [
                  [0,0,0, 0,5,0, 8,0,0],  // Cols 1 & 2 can only be {3,7}
                  [4,5,6, 1,8,2, 9,3,7],
                  [7,8,9, 3,4,6, 1,2,5],
                  
                  [2,1,4, 6,9,7, 5,8,3],
                  [3,6,5, 8,2,1, 7,4,9],
                  [8,9,7, 5,3,4, 2,6,1],
                  
                  [5,2,1, 7,6,8, 3,9,4],
                  [6,4,8, 9,1,3, 0,5,2],
                  [9,7,3, 2,0,5, 6,1,8],
                ],
                highlightCells: [0, 0, 0, 1], // Cells at (0,0) and (0,1)
                description: 'Cells in row 1, columns 1-2 can only contain {3,7}. '
                    'Remove 3 and 7 from all other cells in row 1.',
              ),
              SizedBox(height: 24),

              // ── Hidden Pairs ───────────────────────────────────────────
              Text('2. Hidden Pairs', style: _ths),
              SizedBox(height: 4),
              Text(
                'When two digits can only appear in two cells within a row, column, or box, '
                'you can eliminate all other candidates from those two cells.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Example:\n'
                '• In a box, the digits 4 and 9 can only go in cells X and Y\n'
                '• Remove all other candidates from cells X and Y\n'
                '• Now they form a Naked Pair!',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Pointing Pairs ─────────────────────────────────────────
              Text('3. Pointing Pairs/Triples', style: _ths),
              SizedBox(height: 4),
              Text(
                'When all candidates for a digit in a box are aligned in one row or column, '
                'eliminate that digit from the rest of that row or column.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'How it works:\n'
                '• Look at a box (3×3)\n'
                '• Find a digit that appears in only one row/column within that box\n'
                '• Eliminate that digit from the rest of that row/column outside the box',
                style: _ts,
              ),
              SizedBox(height: 4),
              _TechniqueNote(
                note: 'Also called "Locked Candidates" — because the candidates are locked to one line.',
              ),
              SizedBox(height: 24),

              // ── Box/Line Reduction ─────────────────────────────────────
              Text('4. Box/Line Reduction', style: _ths),
              SizedBox(height: 4),
              Text(
                'When all candidates for a digit in a row or column fall within a single box, '
                'eliminate that digit from the rest of that box.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Example:\n'
                '• In row 1, digit 8 can only appear in columns 4, 5, or 6 (box 2)\n'
                '• Remove 8 from all other cells in box 2',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Naked Triples ──────────────────────────────────────────
              Text('5. Naked Triples', style: _ths),
              SizedBox(height: 4),
              Text(
                'When three cells in the same unit share exactly three candidates between them, '
                'those digits can be eliminated from other cells.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Pattern recognition:\n'
                '• Cell A: {2,5}\n'
                '• Cell B: {5,8}\n'
                '• Cell C: {2,8}\n'
                '• Together they cover {2,5,8} — remove these from other cells in the unit',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Tips ───────────────────────────────────────────────────
              Text('Intermediate Tips', style: _ths),
              SizedBox(height: 6),
              Text(
                '✓ Keep pencil-marks clean and up-to-date\n'
                '✓ Look for pairs first (easier to spot)\n'
                '✓ Check all three units: rows, columns, AND boxes\n'
                '✓ Pointing Pairs often lead to immediate placements\n'
                '✓ Combine techniques — one elimination often triggers another',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Practice ───────────────────────────────────────────────
              _PracticeCard(
                title: 'Practice Makes Perfect',
                description: 'These techniques require pattern recognition. Try Hard puzzles '
                    'and look specifically for these patterns. Once comfortable, explore Advanced techniques.',
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechniqueNote extends StatelessWidget {
  final String note;

  const _TechniqueNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.white.withOpacity(0.6), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: _ts.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String title;
  final String description;

  const _PracticeCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal.withOpacity(0.2), _teal.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline, color: _teal, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _teal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: _ts.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _SudokuGrid extends StatelessWidget {
  final String title;
  final List<List<int>> grid;
  final List<int> highlightCells;
  final String description;

  const _SudokuGrid({
    required this.title,
    required this.grid,
    required this.highlightCells,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Convert highlightCells list to set of (row, col) pairs
    final highlights = <String>{};
    for (int i = 0; i < highlightCells.length; i += 2) {
      if (i + 1 < highlightCells.length) {
        highlights.add('${highlightCells[i]}_${highlightCells[i + 1]}');
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _teal,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                children: List.generate(9, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(9, (col) {
                      final isHighlighted = highlights.contains('${row}_$col');
                      final value = grid[row][col];
                      
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? Colors.yellow.withOpacity(0.3)
                              : (row ~/ 3 + col ~/ 3) % 2 == 0
                                  ? Colors.grey.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                          border: Border(
                            right: col % 3 == 2 && col != 8
                                ? const BorderSide(color: Colors.white, width: 2)
                                : const BorderSide(color: Colors.white30, width: 0.5),
                            bottom: row % 3 == 2 && row != 8
                                ? const BorderSide(color: Colors.white, width: 2)
                                : const BorderSide(color: Colors.white30, width: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            value == 0 ? '' : value.toString(),
                            style: TextStyle(
                              color: isHighlighted ? Colors.yellow : Colors.white,
                              fontSize: 13,
                              fontWeight: value == 0 ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: _ts.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
