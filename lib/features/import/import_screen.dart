import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../game/game_state.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pasteController = TextEditingController();
  String? _pasteError;
  final List<int> _manualGrid = List.filled(81, 0); // 0 = empty

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  bool _validate81(String s) {
    final cleaned = s.replaceAll(RegExp(r'\s'), '');
    return RegExp(r'^[0-9]{81}$').hasMatch(cleaned);
  }

  void _loadFromString() {
    final raw = _pasteController.text.replaceAll(RegExp(r'\s'), '');
    if (!_validate81(raw)) {
      setState(() => _pasteError =
          'Enter exactly 81 digits (0–9). Got ${raw.length}.');
      return;
    }
    setState(() => _pasteError = null);
    ref.read(gameProvider.notifier).startImportedGame(raw);
    context.go('/game');
  }

  void _saveManualGrid() {
    final s = _manualGrid.map((d) => d.toString()).join();
    ref.read(gameProvider.notifier).startImportedGame(s);
    context.go('/game');
  }

  void _pickDigit(int idx) {
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Set digit (row ${idx ~/ 9 + 1}, col ${idx % 9 + 1})',
          style: const TextStyle(color: Color(0xFF0D9488), fontSize: 14),
        ),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int d = 0; d <= 9; d++)
              InkWell(
                onTap: () => Navigator.pop(ctx, d),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _manualGrid[idx] == d && d != 0
                        ? const Color(0xFF0D9488)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    d == 0 ? '×' : '$d',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).then((picked) {
      if (picked != null && mounted) {
        setState(() => _manualGrid[idx] = picked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Import Puzzle',
            style: TextStyle(
                color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white70),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0D9488),
          labelColor: const Color(0xFF0D9488),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.content_paste), text: 'Paste String'),
            Tab(icon: Icon(Icons.grid_on), text: 'Manual Entry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPasteTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildPasteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Paste an 81-character string of digits.\n'
            'Use 0 for empty cells, 1–9 for givens.\n'
            'Row by row, left to right, top to bottom.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pasteController,
            maxLines: 4,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: '530070000600195000...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              errorText: _pasteError,
            ),
            onChanged: (_) {
              if (_pasteError != null) setState(() => _pasteError = null);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _loadFromString,
            child: const Text('Load Puzzle', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tap a cell to set its digit. Leave cells as 0 for empty.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (ctx, bc) {
                  return CustomPaint(
                    painter: _GridLinePainter(),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 9),
                      itemCount: 81,
                      itemBuilder: (_, i) {
                        final d = _manualGrid[i];
                        return InkWell(
                          onTap: () => _pickDigit(i),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: (i % 9 + 1) % 3 == 0 && i % 9 != 8
                                      ? Colors.white60
                                      : Colors.white24,
                                  width:
                                      (i % 9 + 1) % 3 == 0 && i % 9 != 8
                                          ? 1.5
                                          : 0.5,
                                ),
                                bottom: BorderSide(
                                  color: (i ~/ 9 + 1) % 3 == 0 &&
                                          i ~/ 9 != 8
                                      ? Colors.white60
                                      : Colors.white24,
                                  width:
                                      (i ~/ 9 + 1) % 3 == 0 && i ~/ 9 != 8
                                          ? 1.5
                                          : 0.5,
                                ),
                              ),
                            ),
                            child: d == 0
                                ? null
                                : Text(
                                    '$d',
                                    style: const TextStyle(
                                      color: Color(0xFF0D9488),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () =>
                      setState(() => _manualGrid.fillRange(0, 81, 0)),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveManualGrid,
                  child: const Text('Save Grid & Play',
                      style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 2;
    final cellSize = size.width / 9;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
          Offset(cellSize * i * 3, 0),
          Offset(cellSize * i * 3, size.height),
          paint);
      canvas.drawLine(
          Offset(0, cellSize * i * 3),
          Offset(size.width, cellSize * i * 3),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
