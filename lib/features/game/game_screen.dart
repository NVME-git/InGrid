import 'dart:async';
import 'package:flutter/material.dart';
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
      body: SafeArea(
        child: game.isComplete
            ? _CompletionOverlay(elapsed: game.elapsed)
            : isLandscape
                ? _LandscapeLayout(toolbarOnRight: _toolbarOnRight)
                : const _PortraitLayout(),
      ),
    );
  }
}

/// Portrait: grid on top, toolbar at bottom.
class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
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
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: DigitToolbar(),
        ),
      ],
    );
  }
}

/// Landscape: grid fills the taller dimension; toolbar sits to the left or right.
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

    final toolbarWidget = SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: SingleChildScrollView(
          child: const DigitToolbar(),
        ),
      ),
    );

    return Row(
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
