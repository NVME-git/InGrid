import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/persistence_service.dart';
import '../../core/engine/engine.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await PersistenceService.loadHistory();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  String _difficultyLabel(Difficulty d) {
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}/'
        '${dt.month.toString().padLeft(2,'0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2,'0')}:'
        '${dt.minute.toString().padLeft(2,'0')}';
  }

  void _share(GameRecord record) {
    Clipboard.setData(ClipboardData(text: record.toShareString())).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Board state copied to clipboard (81 digits, 0=empty)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _changeDifficulty(GameRecord record, Difficulty newDiff) async {
    await PersistenceService.updateRecordDifficulty(record.id, newDiff);
    await _load();
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
          'Game History',
          style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : _records.isEmpty
              ? const Center(
                  child: Text(
                    'No games recorded yet.\nComplete a puzzle to see it here!',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _records.length,
                  itemBuilder: (context, i) {
                    final rec = _records[i];
                    return _GameRecordCard(
                      record: rec,
                      difficultyLabel: _difficultyLabel(rec.difficulty),
                      elapsedLabel: _formatElapsed(rec.elapsed),
                      dateLabel: _formatDate(rec.date),
                      onShare: () => _share(rec),
                      onChangeDifficulty: rec.isImported
                          ? (d) => _changeDifficulty(rec, d)
                          : null,
                    );
                  },
                ),
    );
  }
}

class _GameRecordCard extends StatelessWidget {
  final GameRecord record;
  final String difficultyLabel;
  final String elapsedLabel;
  final String dateLabel;
  final VoidCallback onShare;
  final void Function(Difficulty)? onChangeDifficulty;

  const _GameRecordCard({
    required this.record,
    required this.difficultyLabel,
    required this.elapsedLabel,
    required this.dateLabel,
    required this.onShare,
    this.onChangeDifficulty,
  });

  void _showDifficultyDialog(BuildContext context) {
    showDialog<Difficulty>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Change Difficulty',
          style: TextStyle(color: Color(0xFF0D9488), fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Difficulty.values.map((d) {
            final label = switch (d) {
              Difficulty.easy => 'Easy',
              Difficulty.medium => 'Medium',
              Difficulty.hard => 'Hard',
              Difficulty.extreme => 'Extreme',
            };
            return ListTile(
              title: Text(label, style: const TextStyle(color: Colors.white70)),
              selected: record.difficulty == d,
              selectedColor: const Color(0xFF0D9488),
              onTap: () => Navigator.pop(ctx, d),
            );
          }).toList(),
        ),
      ),
    ).then((newDiff) {
      if (newDiff != null) onChangeDifficulty?.call(newDiff);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = record.isComplete;
    final statusColor = isComplete ? const Color(0xFF0D9488) : Colors.orange;
    final statusLabel = isComplete ? 'Solved' : 'Incomplete';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        difficultyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (record.isImported) ...[
                        const Icon(Icons.upload_outlined,
                            size: 13, color: Colors.white38),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        elapsedLabel,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Difficulty change (imported only)
            if (onChangeDifficulty != null)
              IconButton(
                icon: const Icon(Icons.tune, size: 18, color: Colors.white38),
                tooltip: 'Change difficulty',
                onPressed: () => _showDifficultyDialog(context),
              ),
            // Share button
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white54),
              tooltip: 'Export board state',
              onPressed: onShare,
            ),
          ],
        ),
      ),
    );
  }
}
