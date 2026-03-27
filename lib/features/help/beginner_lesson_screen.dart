import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D9488);
const _bg = Color(0xFF1A1A2E);
const _ts = TextStyle(color: Colors.white70, fontSize: 13, height: 1.5);
const _ths = TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.bold);
const _subhs = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600);

class BeginnerLessonScreen extends StatelessWidget {
  const BeginnerLessonScreen({super.key});

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
          'Beginner Techniques',
          style: TextStyle(color: _teal, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.school_outlined, color: _teal),
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
              Text('Welcome to Sudoku!', style: _ths),
              SizedBox(height: 8),
              Text(
                'These fundamental techniques will help you solve Easy and Medium puzzles. '
                'Master these before moving on to intermediate strategies.',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Naked Singles ──────────────────────────────────────────
              Text('1. Naked Singles', style: _ths),
              SizedBox(height: 4),
              Text(
                'When a cell can only contain one possible digit (all other digits 1-9 '
                'are already in its row, column, or 3×3 box), that\'s the answer.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'How to find them:\n'
                '• Look for cells with only one pencil-mark candidate\n'
                '• Check which numbers are already in the same row, column, and box\n'
                '• The missing number is your answer',
                style: _ts,
              ),
              SizedBox(height: 4),
              _TechniqueExample(
                example: 'Example: If a cell in row 1 sees digits 1,2,3,4,5,6,7,8 in its '
                    'row/column/box, the only option left is 9.',
              ),
              SizedBox(height: 24),

              // ── Hidden Singles ─────────────────────────────────────────
              Text('2. Hidden Singles', style: _ths),
              SizedBox(height: 4),
              Text(
                'When a digit can only go in one place within a row, column, or box, '
                'even if that cell has multiple candidates.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'How to find them:\n'
                '• Pick a number (e.g., 7)\n'
                '• Look at one row/column/box\n'
                '• Find where that number can go\n'
                '• If only one cell works, place it there',
                style: _ts,
              ),
              SizedBox(height: 4),
              _TechniqueExample(
                example: 'Example: In box 1, if the digit 5 can only fit in one cell '
                    '(all other cells already see a 5), place 5 there.',
              ),
              SizedBox(height: 24),

              // ── Scanning ────────────────────────────────────────────────
              Text('3. Cross-Hatching (Scanning)', style: _ths),
              SizedBox(height: 4),
              Text(
                'Look for a number that appears frequently across the grid. Use existing '
                'placements to eliminate cells and find where it must go next.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'How to scan:\n'
                '• Pick a number that appears 4+ times already\n'
                '• Focus on boxes that don\'t have it yet\n'
                '• Draw imaginary lines from existing numbers\n'
                '• Find the cell that all lines miss',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Process of Elimination ─────────────────────────────────
              Text('4. Process of Elimination', style: _ths),
              SizedBox(height: 4),
              Text(
                'Systematically mark candidate numbers in empty cells, then eliminate '
                'candidates as you place digits.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Steps:\n'
                '• Use pencil-marks to note possible candidates\n'
                '• When you place a digit, remove it from all cells in the same row/column/box\n'
                '• Keep your candidates updated as you progress',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Tips ───────────────────────────────────────────────────
              Text('Beginner Tips', style: _ths),
              SizedBox(height: 6),
              Text(
                '✓ Start with rows/columns/boxes that have the most givens\n'
                '✓ Use the auto-candidates feature (≡ icon) to see possibilities\n'
                '✓ Focus on one number at a time when scanning\n'
                '✓ Double-check each placement before moving on\n'
                '✓ If stuck, try a different number or technique',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Practice ───────────────────────────────────────────────
              _PracticeCard(
                title: 'Ready to Practice?',
                description: 'Start with Easy or Medium puzzles to master these techniques. '
                    'Once you can solve Medium puzzles consistently, move on to Intermediate strategies.',
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechniqueExample extends StatelessWidget {
  final String example;

  const _TechniqueExample({required this.example});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _teal.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: _teal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              example,
              style: _ts.copyWith(color: Colors.white.withOpacity(0.9)),
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
            children: const [
              Icon(Icons.play_circle_outline, color: _teal, size: 24),
              SizedBox(width: 8),
              Text(
                'Ready to Practice?',
                style: TextStyle(
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
