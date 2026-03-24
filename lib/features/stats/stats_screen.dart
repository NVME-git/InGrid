import 'package:flutter/material.dart';
import '../../services/persistence_service.dart';
import '../../core/engine/engine.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, List<Map<String, dynamic>>> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await PersistenceService.loadStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text(
          'Statistics',
          style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final difficulties = [
      Difficulty.easy,
      Difficulty.medium,
      Difficulty.hard,
      Difficulty.extreme,
    ];
    final labels = ['Easy', 'Medium', 'Hard', 'Extreme'];

    bool hasAny = false;
    for (final d in difficulties) {
      final entries = _stats[d.name] ?? [];
      if (entries.isNotEmpty) { hasAny = true; break; }
    }

    if (!hasAny) {
      return const Center(
        child: Text(
          'No solved puzzles yet.\nComplete a game to see your stats!',
          style: TextStyle(color: Colors.white54, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < difficulties.length; i++)
          _DifficultyStatsCard(
            label: labels[i],
            entries: _stats[difficulties[i].name] ?? [],
            formatTime: _formatTime,
          ),
      ],
    );
  }
}

class _DifficultyStatsCard extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> entries;
  final String Function(int) formatTime;

  const _DifficultyStatsCard({
    required this.label,
    required this.entries,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final times = entries.map((e) => e['secs'] as int).toList()..sort();
    final avg = times.fold(0, (a, b) => a + b) ~/ times.length;
    final best = times.first;
    final count = times.length;

    // Trend: last 7 days vs previous 7 days
    final now = DateTime.now();
    final cutoff7 = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final last7 = entries
        .where((e) => (e['date_ms'] as int) >= cutoff7)
        .map((e) => e['secs'] as int)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0D9488),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white12, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Games', value: '$count'),
                _StatItem(label: 'Best', value: formatTime(best)),
                _StatItem(label: 'Average', value: formatTime(avg)),
                if (last7.isNotEmpty)
                  _StatItem(
                    label: 'Last 7d avg',
                    value: formatTime(
                      last7.fold(0, (a, b) => a + b) ~/ last7.length,
                    ),
                  ),
              ],
            ),
            if (entries.length > 1) ...[
              const SizedBox(height: 12),
              const Text(
                'Recent completions',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              _MiniTimelineChart(entries: entries),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

/// Tiny bar chart showing the last 20 completion times.
class _MiniTimelineChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const _MiniTimelineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Show last 20, oldest on the left.
    final recent = entries.take(20).toList().reversed.toList();
    final times = recent.map((e) => e['secs'] as int).toList();
    final maxT = times.fold(0, (a, b) => a > b ? a : b);
    if (maxT == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: times.map((t) {
          final frac = t / maxT;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: 40 * frac,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
