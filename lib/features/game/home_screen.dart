import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game_state.dart';
import '../../core/engine/engine.dart';
import '../../services/persistence_service.dart';
import '../../services/pwa_helper.dart';
import '../../services/theme_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  SavedGame? _savedGame;
  bool _checkingStorage = true;
  bool _showInstallBanner = false;
  bool _isIos = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
    _checkInstallBanner();
  }

  Future<void> _checkInstallBanner() async {
    if (isStandalonePwa()) return; // already installed – never show
    final dismissed = await PersistenceService.isPwaInstallBannerDismissed();
    if (mounted && !dismissed) {
      setState(() {
        _showInstallBanner = true;
        _isIos = isIosBrowser();
      });
    }
  }

  Future<void> _dismissInstallBanner() async {
    setState(() => _showInstallBanner = false);
    await PersistenceService.dismissPwaInstallBanner();
  }

  Future<void> _checkSavedGame() async {
    final saved = await PersistenceService.loadCurrentGame();
    if (mounted)
      setState(() {
        _savedGame = saved;
        _checkingStorage = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
        ],
      ),
      bottomNavigationBar: _showInstallBanner
          ? _InstallBanner(isIos: _isIos, onDismiss: _dismissInstallBanner)
          : null,
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
                  Text(
                    'Sudoku',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

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

                  // ── New Grid ──────────────────────────────────────────────
                  const _SectionLabel('New Grid'),
                  _ButtonRow(
                    children: Difficulty.values
                        .map(
                          (d) => _SectionBtn(
                            label: _diffLabel(d),
                            onPressed: () {
                              ref.read(gameProvider.notifier).startNewGame(d);
                              context.go('/game');
                            },
                          ),
                        )
                        .toList(),
                  ),

                  // ── Import Grid ───────────────────────────────────────────
                  const _SectionLabel('Import Grid'),
                  _ButtonRow(
                    children: [
                      _SectionBtn(
                        label: 'Paste',
                        icon: Icons.content_paste_outlined,
                        onPressed: () => context.go('/import', extra: 'paste'),
                      ),
                      _SectionBtn(
                        label: 'Write',
                        icon: Icons.edit_outlined,
                        onPressed: () => context.go('/import', extra: 'write'),
                      ),
                    ],
                  ),

                  // ── Learn ─────────────────────────────────────────────────
                  const _SectionLabel('Learn'),
                  _ButtonRow(
                    children: [
                      _SectionBtn(
                        label: 'Basics',
                        icon: Icons.help_outline,
                        onPressed: () => context.go('/help'),
                      ),
                      _SectionBtn(
                        label: 'Beginner',
                        icon: Icons.school_outlined,
                        onPressed: () => context.go('/lessons/beginner'),
                      ),
                      _SectionBtn(
                        label: 'Intermediate',
                        icon: Icons.trending_up,
                        onPressed: () => context.go('/lessons/intermediate'),
                      ),
                      _SectionBtn(
                        label: 'Advanced',
                        icon: Icons.verified,
                        onPressed: () => context.go('/lessons/advanced'),
                      ),
                    ],
                  ),

                  // ── Progress ──────────────────────────────────────────────
                  const _SectionLabel('Progress'),
                  _ButtonRow(
                    children: [
                      _SectionBtn(
                        label: 'History',
                        icon: Icons.history,
                        onPressed: () => context.go('/history'),
                      ),
                      _SectionBtn(
                        label: 'Statistics',
                        icon: Icons.bar_chart,
                        onPressed: () => context.go('/stats'),
                      ),
                    ],
                  ),

                  // ── Support ───────────────────────────────────────────────
                  const SizedBox(height: 24),
                  const _BuyMeCoffeeButton(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _diffLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.extreme:
        return 'Extreme';
    }
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
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.54),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A horizontal row of equally-spaced buttons that fills the available width.
class _ButtonRow extends StatelessWidget {
  final List<Widget> children;
  const _ButtonRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single button inside a _ButtonRow.
class _SectionBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool muted;

  const _SectionBtn({
    required this.label,
    this.icon,
    required this.onPressed,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fg = muted
        ? onSurface.withValues(alpha: 0.38)
        : enabled
        ? Colors.white
        : onSurface.withValues(alpha: 0.38);
    final bg = muted
        ? Colors.transparent
        : enabled
        ? const Color(0xFF0D9488).withValues(alpha: 0.85)
        : onSurface.withValues(alpha: 0.08);
    final border = muted
        ? onSurface.withValues(alpha: 0.12)
        : enabled
        ? const Color(0xFF0D9488)
        : onSurface.withValues(alpha: 0.12);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(height: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
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
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.extreme:
        return 'Extreme';
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
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
          foregroundColor: const Color(0xFF0D9488),
          side: const BorderSide(color: Color(0xFF0D9488)),
          minimumSize: const Size(double.infinity, 72),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 36),
            const SizedBox(height: 6),
            const Text(
              'Continue Grid',
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

class _BuyMeCoffeeButton extends StatelessWidget {
  const _BuyMeCoffeeButton();

  static final _url = Uri.parse('https://buymeacoffee.com/nabeelvandayar');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open buymeacoffee.com'),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDD00),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 20, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Buy me a coffee',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallBanner extends StatelessWidget {
  final bool isIos;
  final VoidCallback onDismiss;

  const _InstallBanner({required this.isIos, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: const Color(0xFF0D9488).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.add_to_home_screen,
                color: Color(0xFF0D9488),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add to Home Screen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (isIos)
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.72),
                        ),
                        children: const [
                          TextSpan(text: 'Tap the '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.ios_share,
                              size: 14,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          TextSpan(text: ' share button, then '),
                          TextSpan(
                            text: '"Add to Home Screen"',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          TextSpan(text: ' to install InGrid.'),
                        ],
                      ),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.72),
                        ),
                        children: const [
                          TextSpan(text: 'Tap the '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.more_vert,
                              size: 14,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          TextSpan(text: ' menu, then '),
                          TextSpan(
                            text: '"Add to Home Screen"',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          TextSpan(text: ' to install InGrid.'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: onSurface.withValues(alpha: 0.54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
