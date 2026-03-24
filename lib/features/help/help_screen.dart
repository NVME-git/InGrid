import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _teal = Color(0xFF0D9488);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: GestureDetector(
          onTap: () => context.go('/'),
          child: const Center(
            child: Text(
              'InGrid',
              style: TextStyle(
                color: _teal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        title: const Text('How to Play'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.help_outline, color: _teal),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Text(
              'How to Play InGrid',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Goal ─────────────────────────────────────────────────────
            _HelpSection(
              title: 'Goal',
              children: [
                Text(
                  'Fill every cell in the 9×9 grid so that each row, each column, '
                  'and each 3×3 box contains every digit from 1 to 9 exactly once. '
                  'No digit may repeat within any row, column, or box.',
                  style: TextStyle(color: onSurface),
                ),
              ],
            ),

            // ── Entry Modes ───────────────────────────────────────────────
            _HelpSection(
              title: 'Entry Modes',
              children: [
                _ModeTable(onSurface: onSurface),
                const SizedBox(height: 12),
                _ExampleModeWidget(onSurface: onSurface),
              ],
            ),

            // ── Toolbar ───────────────────────────────────────────────────
            _HelpSection(
              title: 'Toolbar',
              children: [
                _ToolbarRow(
                  icon: Icons.undo,
                  shortcut: 'Z',
                  label: 'Undo',
                  description: 'Step back one move',
                  onSurface: onSurface,
                ),
                _ToolbarRow(
                  icon: Icons.redo,
                  shortcut: 'Y',
                  label: 'Redo',
                  description: 'Step forward one move',
                  onSurface: onSurface,
                ),
                _ToolbarRow(
                  icon: Icons.deselect,
                  shortcut: 'Esc',
                  label: 'Deselect',
                  description: 'Clear the current selection',
                  onSurface: onSurface,
                ),
                _ToolbarRow(
                  icon: Icons.backspace_outlined,
                  shortcut: 'Del',
                  label: 'Erase',
                  description: 'Remove digit or notes from selected cell(s)',
                  onSurface: onSurface,
                ),
                const SizedBox(height: 8),
                Text(
                  'Multi-Nums / Multi-Crnrs / Multi-Cntrs',
                  style: TextStyle(
                    color: _teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activate multi-cell select mode for the corresponding entry mode. '
                  'Drag across multiple cells then type a digit to apply it to all selected cells at once.',
                  style: TextStyle(color: onSurface, fontSize: 13),
                ),
              ],
            ),

            // ── AppBar Icons ──────────────────────────────────────────────
            _HelpSection(
              title: 'AppBar Icons',
              children: [
                _AppBarIconsRow(onSurface: onSurface),
              ],
            ),

            // ── Keyboard Shortcuts ────────────────────────────────────────
            _HelpSection(
              title: 'Keyboard Shortcuts',
              children: [
                _ShortcutsTable(onSurface: onSurface),
              ],
            ),

            // ── Long-press Digit ──────────────────────────────────────────
            _HelpSection(
              title: 'Long-press Digit',
              children: [
                Text(
                  'Long-pressing a digit button (1–9) in the toolbar activates '
                  'multi-select mode for the current entry mode. You can then '
                  'drag or tap multiple cells; when you release, the digit is '
                  'applied to all highlighted cells simultaneously.',
                  style: TextStyle(color: onSurface),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section wrapper ─────────────────────────────────────────────────

class _HelpSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _HelpSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          title,
          style: const TextStyle(
            color: _teal,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }
}

// ── Entry mode table ─────────────────────────────────────────────────────────

class _ModeTable extends StatelessWidget {
  final Color onSurface;
  const _ModeTable({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Num (N)', 'Place a digit in the selected cell'],
      ['Corner (V)', 'Small pencil-marks in the cell corner'],
      ['Centre (C)', 'Large pencil-mark in the cell centre'],
      ['Color', 'Paint a cell with a highlight color'],
    ];
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _teal.withValues(alpha: 0.4))),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 12),
              child: Text('Mode', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Description', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        for (final row in rows)
          TableRow(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
              child: Text(row[0], style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(row[1], style: TextStyle(color: onSurface, fontSize: 13)),
            ),
          ]),
      ],
    );
  }
}

// ── Example mode visual ──────────────────────────────────────────────────────

class _ExampleModeWidget extends StatelessWidget {
  final Color onSurface;
  const _ExampleModeWidget({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CellExample(
          label: 'Num',
          child: Text('7', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _teal)),
        ),
        _CellExample(
          label: 'Corner',
          child: Align(
            alignment: Alignment.topLeft,
            child: Text('1 3', style: TextStyle(fontSize: 9, color: onSurface.withValues(alpha: 0.7))),
          ),
        ),
        _CellExample(
          label: 'Centre',
          child: Center(
            child: Text('25', style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.7))),
          ),
        ),
        _CellExample(
          label: 'Color',
          child: Container(color: Colors.yellow.withValues(alpha: 0.4)),
        ),
      ],
    );
  }
}

class _CellExample extends StatelessWidget {
  final String label;
  final Widget child;
  const _CellExample({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: _teal.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(3),
          child: child,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _teal)),
      ],
    );
  }
}

// ── Toolbar row ──────────────────────────────────────────────────────────────

class _ToolbarRow extends StatelessWidget {
  final IconData icon;
  final String shortcut;
  final String label;
  final String description;
  final Color onSurface;

  const _ToolbarRow({
    required this.icon,
    required this.shortcut,
    required this.label,
    required this.description,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _teal),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: _teal.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(shortcut, style: const TextStyle(fontSize: 11, color: _teal, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          Text('$label — ', style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(description, style: TextStyle(color: onSurface.withValues(alpha: 0.8), fontSize: 13))),
        ],
      ),
    );
  }
}

// ── AppBar icons row ─────────────────────────────────────────────────────────

class _AppBarIconsRow extends StatelessWidget {
  final Color onSurface;
  const _AppBarIconsRow({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.pause, 'Pause'),
      (Icons.edit_outlined, 'Auto-candidates'),
      (Icons.tips_and_updates_outlined, 'Hints\n(soon)'),
      (Icons.visibility, 'Conflicts'),
      (Icons.help_outline, 'Help'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map((item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, size: 22, color: _teal),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(fontSize: 10, color: onSurface.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ))
          .toList(),
    );
  }
}

// ── Keyboard shortcuts table ─────────────────────────────────────────────────

class _ShortcutsTable extends StatelessWidget {
  final Color onSurface;
  const _ShortcutsTable({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1–9', 'Enter digit'],
      ['N', 'Number mode'],
      ['V', 'Corner note mode'],
      ['C', 'Centre note mode'],
      ['M', 'Toggle multi-select'],
      ['P', 'Toggle pause'],
      ['Z', 'Undo'],
      ['Y', 'Redo'],
      ['Delete / ⌫', 'Erase'],
      ['Escape', 'Deselect all'],
    ];
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _teal.withValues(alpha: 0.4))),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 16),
              child: Text('Key', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Action', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        for (final row in rows)
          TableRow(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: _teal.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  row[0],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: _teal),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(row[1], style: TextStyle(color: onSurface, fontSize: 13)),
            ),
          ]),
      ],
    );
  }
}
