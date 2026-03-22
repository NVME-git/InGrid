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
            : Column(
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    child: const DigitToolbar(),
                  ),
                ],
              ),
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
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
