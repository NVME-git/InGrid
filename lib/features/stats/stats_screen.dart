import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        leadingWidth: 80,
        leading: GestureDetector(
          onTap: () => context.go('/'),
          child: const Center(
            child: Text(
              'InGrid',
              style: TextStyle(
                color: Color(0xFF0D9488),
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
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

    final now = DateTime.now();
    final cutoff7 = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final last7Entries =
        entries.where((e) => (e['date_ms'] as int) >= cutoff7).toList();
    final last7 = last7Entries.map((e) => e['secs'] as int).toList();

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
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => _TrendLineSheet(
                        entries: last7Entries,
                        formatTime: formatTime,
                        label: label,
                      ),
                    ),
                    child: _StatItem(
                      label: 'Last 7d avg ›',
                      value: formatTime(
                        last7.fold(0, (a, b) => a + b) ~/ last7.length,
                      ),
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

// ── Trend line bottom sheet ───────────────────────────────────────────────────

class _TrendLineSheet extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final String Function(int) formatTime;
  final String label;

  const _TrendLineSheet({
    required this.entries,
    required this.formatTime,
    required this.label,
  });

  @override
  State<_TrendLineSheet> createState() => _TrendLineSheetState();
}

class _TrendLineSheetState extends State<_TrendLineSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns 7 values (oldest first) — null means no data for that day.
  List<double?> _dailyAverages() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final ms0 = day.millisecondsSinceEpoch;
      final ms1 = ms0 + const Duration(days: 1).inMilliseconds;
      final vals = widget.entries
          .where((e) {
            final t = e['date_ms'] as int;
            return t >= ms0 && t < ms1;
          })
          .map((e) => (e['secs'] as int).toDouble())
          .toList();
      return vals.isEmpty
          ? null
          : vals.reduce((a, b) => a + b) / vals.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _dailyAverages();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.label} – Last 7 Days',
            style: const TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Daily average completion time',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _progress,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _LineChartPainter(
                  data: data,
                  progress: _progress.value,
                  formatTime: widget.formatTime,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double?> data; // 7 values (oldest→newest), null = no data
  final double progress; // 0..1 animation progress
  final String Function(int) formatTime;

  _LineChartPainter({
    required this.data,
    required this.progress,
    required this.formatTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nonNull = data.whereType<double>().toList();
    if (nonNull.isEmpty) return;

    final maxVal = nonNull.reduce((a, b) => a > b ? a : b);
    final minVal = nonNull.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    const leftPad = 44.0;
    const bottomPad = 28.0;
    const topPad = 8.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    // ── Grid lines & y-axis labels ──────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 3; i++) {
      final y = topPad + (i / 3) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final secs = (minVal + (1 - i / 3) * range).toInt().clamp(0, 999999);
      final label = formatTime(secs);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── X-axis day labels ───────────────────────────────────────────────────
    final now = DateTime.now();
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: 6 - i));
      final label = days[d.weekday % 7];
      final x = leftPad + (i / 6) * chartW;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, size.height - bottomPad + 4));
    }

    // ── Compute pixel positions ─────────────────────────────────────────────
    final points = <Offset?>[];
    for (int i = 0; i < 7; i++) {
      final x = leftPad + (i / 6) * chartW;
      if (data[i] == null) {
        points.add(null);
      } else {
        final y = topPad + (1 - (data[i]! - minVal) / range) * chartH;
        points.add(Offset(x, y));
      }
    }

    // ── Build segments between consecutive non-null points ──────────────────
    final segments = <(Offset, Offset)>[];
    Offset? prev;
    for (int i = 0; i < 7; i++) {
      if (points[i] != null) {
        if (prev != null) segments.add((prev, points[i]!));
        prev = points[i];
      }
    }

    // ── Draw lines (animated) ───────────────────────────────────────────────
    final linePaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (segments.isNotEmpty) {
      final drawUpTo = progress * segments.length;
      for (int s = 0; s < segments.length; s++) {
        if (s >= drawUpTo) break;
        final frac = (drawUpTo - s).clamp(0.0, 1.0);
        final actualEnd = Offset.lerp(segments[s].$1, segments[s].$2, frac)!;
        canvas.drawLine(segments[s].$1, actualEnd, linePaint);
      }
    }

    // ── Draw dots ───────────────────────────────────────────────────────────
    final dotFill = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.fill;
    final dotOutline = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 7; i++) {
      if (points[i] == null) continue;
      if ((i / 6.0) > progress && i != 0) continue;
      canvas.drawCircle(points[i]!, 4, dotOutline);
      canvas.drawCircle(points[i]!, 4, dotFill);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}

