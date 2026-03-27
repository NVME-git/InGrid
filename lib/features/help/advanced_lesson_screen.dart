import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D9488);
const _bg = Color(0xFF1A1A2E);
const _ts = TextStyle(color: Colors.white70, fontSize: 13, height: 1.5);
const _ths = TextStyle(color: _teal, fontSize: 15, fontWeight: FontWeight.bold);
const _subhs = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600);

class AdvancedLessonScreen extends StatelessWidget {
  const AdvancedLessonScreen({super.key});

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
          'Advanced Techniques',
          style: TextStyle(color: _teal, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.verified, color: _teal),
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
              Text('Master-Level Strategies', style: _ths),
              SizedBox(height: 8),
              Text(
                'These powerful techniques will help you solve Extreme puzzles and the hardest '
                'Sudoku challenges. They require patience, careful analysis, and pattern recognition.',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── X-Wing ─────────────────────────────────────────────────
              Text('1. X-Wing', style: _ths),
              SizedBox(height: 4),
              Text(
                'When a candidate appears in exactly two positions in two parallel rows (or columns), '
                'and those positions align vertically (or horizontally), you can eliminate that '
                'candidate from the intersecting columns (or rows).',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Pattern structure:\n'
                '• Find a digit that appears exactly twice in two rows\n'
                '• Check if they line up in the same columns\n'
                '• If yes: eliminate that digit from those columns (except the X-Wing cells)',
                style: _ts,
              ),
              SizedBox(height: 4),
              _TechniqueExample(
                example: 'Example: Digit 5 appears in row 2 (cols 3,8) and row 6 (cols 3,8). '
                    'Remove all 5s from columns 3 and 8 except in rows 2 and 6.',
              ),
              SizedBox(height: 24),

              // ── Swordfish ──────────────────────────────────────────────
              Text('2. Swordfish', style: _ths),
              SizedBox(height: 4),
              Text(
                'An extension of X-Wing using three rows and three columns. When a candidate '
                'appears 2-3 times in three parallel rows, and they align in three columns, '
                'eliminate from those columns.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Harder to find but powerful:\n'
                '• Look across three rows\n'
                '• A candidate appears 2-3 times per row\n'
                '• They align in exactly three columns\n'
                '• Eliminate from those three columns',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── XY-Wing ────────────────────────────────────────────────
              Text('3. XY-Wing', style: _ths),
              SizedBox(height: 4),
              Text(
                'Uses three cells with two candidates each, forming a chain. If the "pivot" cell '
                'has candidates {X,Y}, and two "wing" cells have {X,Z} and {Y,Z}, you can eliminate '
                'Z from cells that see both wings.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Finding XY-Wings:\n'
                '• Find a cell with two candidates (pivot): {X,Y}\n'
                '• Find a cell it sees with {X,Z} (wing 1)\n'
                '• Find another cell it sees with {Y,Z} (wing 2)\n'
                '• Eliminate Z from cells that see both wing cells',
                style: _ts,
              ),
              SizedBox(height: 4),
              _TechniqueNote(
                note: 'Think of it as: "If pivot is X, wing2 must be Z. If pivot is Y, wing1 must be Z."',
              ),
              SizedBox(height: 24),

              // ── Simple Coloring ────────────────────────────────────────
              Text('4. Simple Coloring', style: _ths),
              SizedBox(height: 4),
              Text(
                'For a candidate that appears exactly twice in several units, create a chain by '
                'coloring them alternately. If two cells of the same color see the same cell, '
                'eliminate the candidate from that cell.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Coloring steps:\n'
                '• Pick a digit that appears as pairs in multiple units\n'
                '• Color one cell blue, the other in that unit orange\n'
                '• Continue coloring connected cells with alternating colors\n'
                '• Look for cells that see two cells of the same color',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── XYZ-Wing ───────────────────────────────────────────────
              Text('5. XYZ-Wing', style: _ths),
              SizedBox(height: 4),
              Text(
                'Similar to XY-Wing, but the pivot has three candidates {X,Y,Z} and the wings '
                'have {X,Z} and {Y,Z}. Eliminates Z from cells seeing all three cells.',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Pattern:\n'
                '• Pivot cell: {X,Y,Z}\n'
                '• Wing 1: {X,Z} (shares unit with pivot)\n'
                '• Wing 2: {Y,Z} (shares unit with pivot)\n'
                '• Eliminate Z from cells that see all three',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Y-Wing ─────────────────────────────────────────────────
              Text('6. Y-Wing (XY-Chain)', style: _ths),
              SizedBox(height: 4),
              Text(
                'A chain-based technique where you link cells with two candidates, creating an '
                'implication chain. Uses strong links (one must be true) and weak links (both can\'t be true).',
                style: _subhs,
              ),
              SizedBox(height: 6),
              Text(
                'Advanced chain logic:\n'
                '• Strong link: If A is false, B must be true\n'
                '• Connect cells through shared candidates\n'
                '• Find contradictions or forced placements\n'
                '• Requires careful logical tracking',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Tips ───────────────────────────────────────────────────
              Text('Advanced Tips', style: _ths),
              SizedBox(height: 6),
              Text(
                '✓ Master intermediate techniques first\n'
                '✓ Start with X-Wing (easiest advanced technique)\n'
                '✓ Use pencil-marks meticulously — accuracy is crucial\n'
                '✓ Look for patterns systematically (check each digit 1-9)\n'
                '✓ Don\'t force it — if stuck, try simpler techniques first\n'
                '✓ Practice pattern recognition with puzzle books',
                style: _ts,
              ),
              SizedBox(height: 24),

              // ── Warning ────────────────────────────────────────────────
              _WarningCard(
                title: 'Expert Territory',
                description: 'These techniques require significant practice. Don\'t be discouraged '
                    'if they feel difficult at first. Work through Extreme puzzles slowly, and the '
                    'patterns will become more recognizable over time.',
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

class _WarningCard extends StatelessWidget {
  final String title;
  final String description;

  const _WarningCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.orange.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Expert Territory',
                style: TextStyle(
                  color: Colors.orange,
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
