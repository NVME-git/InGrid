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
      if (!game.isComplete) {
        ref.read(gameProvider.notifier).updateTimer(
          game.elapsed + const Duration(seconds: 1),
        );
      }
    });
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Keyboard shortcuts ────────────────────────────────────────────────────
  // N = Number mode     V = Corner mode    C = Centre mode
  // M = Multi-toggle    Z = Undo           Y = Redo
  // 1-9 = Enter digit   Delete/Backspace = Erase    Escape = Deselect
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(
          _formatTime(game.elapsed),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 20),
        ),
        centerTitle: true,
        actions: [
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
          IconButton(
            icon: Icon(
              game.showConflicts ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            tooltip: 'Toggle conflict highlights',
            onPressed: () => ref.read(gameProvider.notifier).toggleConflicts(),
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: game.isComplete
              ? _CompletionOverlay(elapsed: game.elapsed)
              : isLandscape
                  ? _LandscapeLayout(toolbarOnRight: _toolbarOnRight)
                  : const _PortraitLayout(),
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
      // Reserve up to 58% of the available height for the grid; in portrait the
      // grid is constrained by width anyway so clamping prevents it from eating
      // all the space on tall phones.
      final gridContainerHeight = min(
        constraints.maxWidth,
        constraints.maxHeight * 0.58,
      );
      return Column(
        children: [
          SizedBox(
            height: gridContainerHeight,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const SudokuGrid(),
                ),
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
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height,
              ),
              child: const SudokuGrid(),
            ),
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
