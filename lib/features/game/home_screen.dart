import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'game_state.dart';
import '../../core/engine/engine.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'InGrid',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Sudoku',
                  style: TextStyle(fontSize: 18, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                const Text(
                  'New Game',
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ...Difficulty.values.map((d) => _DifficultyButton(difficulty: d)),
                const SizedBox(height: 32),
                _ManualEntryButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  final Difficulty difficulty;
  const _DifficultyButton({required this.difficulty});

  String get _label {
    switch (difficulty) {
      case Difficulty.easy: return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard: return 'Hard';
      case Difficulty.extreme: return 'Extreme';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          ref.read(gameProvider.notifier).startNewGame(difficulty);
          context.go('/game');
        },
        child: Text(_label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _ManualEntryButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white30),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        ref.read(gameProvider.notifier).startManualEntry();
        context.go('/game');
      },
      child: const Text('Enter Puzzle Manually', style: TextStyle(fontSize: 16)),
    );
  }
}
