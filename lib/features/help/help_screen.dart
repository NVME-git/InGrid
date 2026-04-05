import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D9488);
const _bg = Color(0xFF1A1A2E);
const _ts = TextStyle(color: Colors.white70, fontSize: 13, height: 1.5);
const _ths = TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.bold);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          'How to Play',
          style: TextStyle(color: _teal, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.help_outline, color: _teal),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // ── Goal ───────────────────────────────────────────────────
              Text('Goal', style: _ths),
              SizedBox(height: 4),
              Text(
                'Fill every cell with a digit 1–9 so each row, column, and '
                '3×3 box contains every digit exactly once.',
                style: _ts,
              ),
              SizedBox(height: 16),

              // ── Entry Modes ─────────────────────────────────────────────
              Text('Modes', style: _ths),
              SizedBox(height: 4),
              Text('Num (N) — place a digit in the selected cell', style: _ts),
              Text('Corner (V) — add corner pencil-marks', style: _ts),
              Text('Centre (C) — add a centre pencil-mark', style: _ts),
              Text('Color — paint a cell with a highlight colour', style: _ts),
              SizedBox(height: 16),

              // ── Toolbar ─────────────────────────────────────────────────
              Text('Toolbar buttons', style: _ths),
              SizedBox(height: 4),
              Text('Undo / Redo — step back or forward through your moves', style: _ts),
              Text('Desel — clear the current cell selection', style: _ts),
              Text('Erase — remove the digit or notes from selected cells', style: _ts),
              Text(
                'Multi-Nums / Multi-Crnrs / Multi-Cntrs — activate multi-cell '
                'mode: drag across cells to select many at once, then enter a digit '
                'to fill them all',
                style: _ts,
              ),
              SizedBox(height: 16),

              // ── AppBar Icons ─────────────────────────────────────────────
              Text('AppBar icons', style: _ths),
              SizedBox(height: 4),
              Text('⏸ Pause — hide the grid and stop the timer', style: _ts),
              Text('≡ Candidates — show computed candidates for empty cells', style: _ts),
              Text('💡 Hints — copies board to clipboard and opens sudokusolver.app', style: _ts),
              Text('👁 Conflicts — highlight cells that break Sudoku rules', style: _ts),
              Text('? Help — this screen', style: _ts),
              SizedBox(height: 16),

              // ── Keyboard Shortcuts ───────────────────────────────────────
              Text('Keyboard shortcuts (web / desktop)', style: _ths),
              SizedBox(height: 4),
              Text('1–9  Enter digit   N  Number mode   V  Corner mode   C  Centre mode', style: _ts),
              Text('M  Toggle multi-select   Z  Undo   Y  Redo   P  Pause', style: _ts),
              Text('Delete / Backspace  Erase   Escape  Deselect all', style: _ts),
              SizedBox(height: 16),

              // ── Long-press Digit ─────────────────────────────────────────
              Text('Long-press a digit button', style: _ths),
              SizedBox(height: 4),
              Text(
                'If writable cells are selected (empty or already filled by you): '
                'fills them with that digit (skips conflicts). '
                'If no cells are selected: highlights all '
                'matching cells and their peers to show candidate positions.',
                style: _ts,
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
