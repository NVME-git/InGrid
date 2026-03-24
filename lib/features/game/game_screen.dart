import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_state.dart';
import 'widgets/sudoku_grid.dart';
import 'widgets/digit_toolbar.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _timer;
  /// In landscape mode, whether the toolbar is on the right side.
  bool _toolbarOnRight = true;
  /// Whether the timer shows seconds (mm:ss) or just minutes (mm m).
  bool _timerShowSeconds = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final game = ref.read(gameProvider);
      if (!game.isComplete && !game.isPaused) {
        ref.read(gameProvider.notifier).updateTimer(
          game.elapsed + const Duration(seconds: 1),
        );
      }
    });
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    if (!_timerShowSeconds) return '${m}m';
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${m.toString().padLeft(2, '0')}:$s';
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'How to Play InGrid',
          style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: _HelpContent(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF0D9488))),
          ),
        ],
      ),
    );
  }

  void _shareBoard() {
    final board = ref.read(gameProvider).board;
    final buf = StringBuffer();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        buf.write(board.cells[r][c].digit ?? '0');
      }
    }
    Clipboard.setData(ClipboardData(text: buf.toString())).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Board copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }).catchError((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // ── Keyboard shortcuts ────────────────────────────────────────────────────
  // N = Number mode     V = Corner mode    C = Centre mode
  // M = Multi-toggle    Z = Undo           Y = Redo
  // P = Pause           1-9 = Enter digit
  // Delete/Backspace = Erase    Escape = Deselect
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final notifier = ref.read(gameProvider.notifier);
    final key = event.logicalKey;

    // Digit keys 1-9 (main keyboard and numpad)
    final digitKeys = {
      LogicalKeyboardKey.digit1: 1, LogicalKeyboardKey.numpad1: 1,
      LogicalKeyboardKey.digit2: 2, LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.digit3: 3, LogicalKeyboardKey.numpad3: 3,
      LogicalKeyboardKey.digit4: 4, LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.digit5: 5, LogicalKeyboardKey.numpad5: 5,
      LogicalKeyboardKey.digit6: 6, LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.digit7: 7, LogicalKeyboardKey.numpad7: 7,
      LogicalKeyboardKey.digit8: 8, LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.digit9: 9, LogicalKeyboardKey.numpad9: 9,
    };
    if (digitKeys.containsKey(key)) {
      notifier.enterDigit(digitKeys[key]!);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyZ) {
      notifier.undo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyY) {
      notifier.redo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN) {
      notifier.setEntryModeAndMulti(EntryMode.fullNumber, false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyV) {
      notifier.setEntryModeAndMulti(EntryMode.cornerNote, false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyC) {
      notifier.setEntryModeAndMulti(EntryMode.centreNote, false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyM) {
      notifier.toggleMultiSelect();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      notifier.togglePause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      notifier.erase();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      notifier.deselectAll();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        leadingWidth: 108,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            const Text(
              'InGrid',
              style: TextStyle(
                color: Color(0xFF0D9488),
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                icon: const Icon(Icons.share_outlined, size: 17, color: Colors.white70),
                tooltip: 'Copy board to clipboard',
                onPressed: _shareBoard,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        title: GestureDetector(
          onTap: () => setState(() => _timerShowSeconds = !_timerShowSeconds),
          child: Text(
            _formatTime(game.elapsed),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 20),
          ),
        ),
        centerTitle: true,
        actions: [
          // Pause / resume
          IconButton(
            icon: Icon(
              game.isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white70,
            ),
            tooltip: game.isPaused ? 'Resume' : 'Pause',
            onPressed: notifier.togglePause,
          ),
          // Auto-candidates toggle (distinct icon from hints)
          IconButton(
            icon: Icon(
              Icons.format_list_numbered_rtl,
              color: game.autoCandidates
                  ? const Color(0xFF0D9488)
                  : Colors.white70,
            ),
            tooltip: game.autoCandidates
                ? 'Hide auto candidates'
                : 'Show auto candidates',
            onPressed: notifier.toggleAutoCandidates,
          ),
          // Hints (non-functional placeholder for future feature)
          IconButton(
            icon: const Icon(Icons.tips_and_updates_outlined, color: Colors.white38),
            tooltip: 'Hints (coming soon)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hints coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // Help / how to play
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white54),
            tooltip: 'How to play',
            onPressed: () => _showHelpDialog(context),
          ),
          // Conflict-highlight toggle (starts off)
          IconButton(
            icon: Icon(
              game.showConflicts ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            tooltip: 'Toggle conflict highlights',
            onPressed: notifier.toggleConflicts,
          ),
          // Landscape side-switch toggle (only shown in landscape)
          if (isLandscape)
            IconButton(
              icon: Icon(
                _toolbarOnRight ? Icons.border_right : Icons.border_left,
                color: Colors.white70,
              ),
              tooltip: _toolbarOnRight
                  ? 'Move controls to left'
                  : 'Move controls to right',
              onPressed: () => setState(() => _toolbarOnRight = !_toolbarOnRight),
            ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: game.isComplete
              ? _CompletionOverlay(elapsed: game.elapsed)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    isLandscape
                        ? _LandscapeLayout(toolbarOnRight: _toolbarOnRight)
                        : const _PortraitLayout(),
                    if (game.isPaused) const _PauseOverlay(),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Portrait: grid at top with fixed square size; toolbar expands to fill the rest.
class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Give the grid up to 65% of available height; width is the binding
      // constraint on web where the window is wide but not very tall.
      final gridContainerHeight = min(
        constraints.maxWidth,
        constraints.maxHeight * 0.65,
      );
      return Column(
        children: [
          SizedBox(
            height: gridContainerHeight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: const SudokuGrid(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: const DigitToolbar(expanded: true),
            ),
          ),
        ],
      );
    });
  }
}

/// Landscape: grid fills the taller dimension; toolbar sits to the left or right
/// and expands to use the full screen height.
class _LandscapeLayout extends StatelessWidget {
  final bool toolbarOnRight;
  const _LandscapeLayout({required this.toolbarOnRight});

  @override
  Widget build(BuildContext context) {
    final gridWidget = Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: const SudokuGrid(),
          ),
        ),
      ),
    );

    // The toolbar column stretches to the full row height so expanded buttons
    // can fill the available vertical space.
    final toolbarWidget = SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: const DigitToolbar(expanded: true),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: toolbarOnRight
          ? [gridWidget, toolbarWidget]
          : [toolbarWidget, gridWidget],
    );
  }
}

/// Shown on top of the game when paused.
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xEE1A1A2E),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_outline, size: 72, color: Colors.white54),
          SizedBox(height: 12),
          Text(
            'Paused',
            style: TextStyle(fontSize: 28, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _CompletionOverlay extends StatelessWidget {
  final Duration elapsed;
  const _CompletionOverlay({required this.elapsed});

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 80),
          const SizedBox(height: 16),
          const Text(
            'Puzzle Complete!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time: ${_formatTime(elapsed)}',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Help content ─────────────────────────────────────────────────────────────

class _HelpContent extends StatelessWidget {
  const _HelpContent();

  @override
  Widget build(BuildContext context) {
    const ts = TextStyle(color: Colors.white70, fontSize: 13, height: 1.5);
    const ths = TextStyle(
      color: Color(0xFF0D9488),
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Goal', style: ths),
        Text(
          'Fill every cell with a digit 1–9 so each row, column, and '
          '3×3 box contains every digit exactly once.',
          style: ts,
        ),
        SizedBox(height: 12),
        Text('Modes', style: ths),
        Text('Num — place a digit in the selected cell', style: ts),
        Text('Corner — add small corner pencil-marks', style: ts),
        Text('Centre — add a larger centre pencil-mark', style: ts),
        Text('Color — paint a cell with a highlight colour', style: ts),
        SizedBox(height: 12),
        Text('Toolbar buttons', style: ths),
        Text('Undo / Redo — step back or forward through your moves', style: ts),
        Text('Desel — clear the current cell selection', style: ts),
        Text('Erase — remove the digit or notes from selected cells', style: ts),
        Text('Multi-Nums / Multi-Crnrs / Multi-Cntrs — activate multi-cell '
            'mode: drag across cells to select many at once, then enter a digit '
            'to fill them all', style: ts),
        SizedBox(height: 12),
        Text('AppBar icons', style: ths),
        Text('⏸ Pause — hide the grid and stop the timer', style: ts),
        Text('≡ Candidates — show computed candidates for empty cells', style: ts),
        Text('💡 Hints — coming soon', style: ts),
        Text('? Help — this dialog', style: ts),
        Text('👁 Conflicts — highlight cells that break Sudoku rules', style: ts),
        SizedBox(height: 12),
        Text('Keyboard shortcuts (web)', style: ths),
        Text('1–9  Enter digit   N  Number mode   V  Corner mode   C  Centre mode', style: ts),
        Text('M  Toggle multi-select   Z  Undo   Y  Redo   P  Pause', style: ts),
        Text('Delete / Backspace  Erase   Escape  Deselect all', style: ts),
        SizedBox(height: 12),
        Text('Long-press a digit button', style: ths),
        Text(
          'If writable cells are selected: fills them with that digit '
          '(skips conflicts). If no cells are selected: highlights all '
          'matching cells and their peers to show candidate positions.',
          style: ts,
        ),
      ],
    );
  }
}
