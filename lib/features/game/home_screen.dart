import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'game_state.dart';
import '../../core/engine/engine.dart';
import '../../services/persistence_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  SavedGame? _savedGame;
  bool _checkingStorage = true;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    final saved = await PersistenceService.loadCurrentGame();
    if (mounted) setState(() { _savedGame = saved; _checkingStorage = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ──────────────────────────────────────────────────
                  const Text(
                    'InGrid',
                    style: TextStyle(
                      fontSize: 52,
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
                  const SizedBox(height: 40),

                  // ── Continue existing game (only if saved) ────────────────
                  if (_checkingStorage)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0D9488),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  else if (_savedGame != null)
                    _ContinueButton(
                      savedGame: _savedGame!,
                      onPressed: () async {
                        final loaded = await ref
                            .read(gameProvider.notifier)
                            .loadSavedGame();
                        if (loaded && mounted) context.go('/game');
                      },
                    ),

                  // ── New game heading ──────────────────────────────────────
                  const _SectionLabel('New Game'),
                  ...Difficulty.values.map((d) => _DifficultyButton(difficulty: d)),

                  const SizedBox(height: 12),

                  // ── Import ────────────────────────────────────────────────
                  const _SectionLabel('Import Puzzle'),
                  _HomeBtn(
                    icon: Icons.edit_outlined,
                    label: 'Enter Manually',
                    onPressed: () => context.go('/import'),
                  ),
                  _HomeBtn(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan with Camera (coming soon)',
                    onPressed: null, // OCR stub
                    muted: true,
                  ),

                  const SizedBox(height: 12),

                  // ── History & Stats ───────────────────────────────────────
                  const _SectionLabel('My Progress'),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeBtn(
                          icon: Icons.history,
                          label: 'Game History',
                          onPressed: () => context.go('/history'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HomeBtn(
                          icon: Icons.bar_chart,
                          label: 'Statistics',
                          onPressed: () => context.go('/stats'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white38,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HomeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool muted;

  const _HomeBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: muted ? Colors.white24 : Colors.white70,
          side: BorderSide(color: muted ? Colors.white12 : Colors.white24),
          minimumSize: const Size(double.infinity, 48),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final SavedGame savedGame;
  final VoidCallback onPressed;

  const _ContinueButton({required this.savedGame, required this.onPressed});

  String _diffLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy: return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard: return 'Hard';
      case Difficulty.extreme: return 'Extreme';
    }
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
          foregroundColor: const Color(0xFF0D9488),
          side: const BorderSide(color: Color(0xFF0D9488)),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.play_circle_outline, size: 22),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Continue Game',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_diffLabel(savedGame.difficulty)} • ${_formatElapsed(savedGame.elapsed)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488)),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          ref.read(gameProvider.notifier).startNewGame(difficulty);
          context.go('/game');
        },
        child: Text(_label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

