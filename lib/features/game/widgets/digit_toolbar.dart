import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_state.dart';

// Compact layout — never overflows in portrait or landscape:
//
//   Row 1:  [Undo]     [1] [2] [3]  [Num]
//   Row 2:  [Redo]     [4] [5] [6]  [Corner]
//   Row 3:  [Deselect] [7] [8] [9]  [Centre]
//   Row 4:  [Erase] [Multi-Nums] [Multi-Corners] [Multi-Centers] [Color]
//   Row 5:  (compact color-picker — only visible in Color mode)
//
// Rows 1–4 use 5 Expanded children separated by 2 px gaps.
// When [expanded] is true every row is wrapped in Expanded so the toolbar
// fills its parent height; buttons grow to fill the available space.

class DigitToolbar extends ConsumerWidget {
  /// When true the toolbar fills its parent's available height so buttons grow
  /// to use the space (portrait/landscape full-height mode).
  final bool expanded;
  const DigitToolbar({super.key, this.expanded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final mode = game.entryMode;
    final multi = game.multiSelectMode;
    final isColor = mode == EntryMode.highlighter;

    // ── Single pass: compute placed counts then derive remaining ─────────
    final placedCounts = List.filled(10, 0); // index 1–9
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final d = game.board.cells[r][c].digit;
        if (d != null) placedCounts[d]++;
      }
    }
    final remaining = List.generate(9, (i) => 9 - placedCounts[i + 1]);

    // ── Build the 4 button rows (shared between compact and expanded modes) ──
    final xAlign =
        expanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center;

    final row1 = _ToolRow(crossAxisAlignment: xAlign, children: [
      _ActionBtn(icon: Icons.undo, label: 'Undo', onTap: notifier.undo),
      _DigitBtn(digit: 1, remaining: remaining[0], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _DigitBtn(digit: 2, remaining: remaining[1], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _DigitBtn(digit: 3, remaining: remaining[2], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _ModeBtn(
        label: 'Num',
        icon: Icons.grid_4x4,
        active: mode == EntryMode.fullNumber && !multi,
        onTap: () => notifier.setEntryModeAndMulti(EntryMode.fullNumber, false),
      ),
    ]);
    final row2 = _ToolRow(crossAxisAlignment: xAlign, children: [
      _ActionBtn(icon: Icons.redo, label: 'Redo', onTap: notifier.redo),
      _DigitBtn(digit: 4, remaining: remaining[3], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _DigitBtn(digit: 5, remaining: remaining[4], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _DigitBtn(digit: 6, remaining: remaining[5], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _ModeBtn(
        label: 'Corner',
        icon: Icons.format_list_numbered,
        active: mode == EntryMode.cornerNote && !multi,
        onTap: () => notifier.setEntryModeAndMulti(EntryMode.cornerNote, false),
      ),
    ]);
    final row3 = _ToolRow(crossAxisAlignment: xAlign, children: [
      _ActionBtn(icon: Icons.deselect, label: 'Desel', onTap: notifier.deselectAll),
      _DigitBtn(digit: 7, remaining: remaining[6], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _DigitBtn(digit: 8, remaining: remaining[7], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _DigitBtn(digit: 9, remaining: remaining[8], disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
      _ModeBtn(
        label: 'Centre',
        icon: Icons.notes,
        active: mode == EntryMode.centreNote && !multi,
        onTap: () => notifier.setEntryModeAndMulti(EntryMode.centreNote, false),
      ),
    ]);
    final row4 = _ToolRow(crossAxisAlignment: xAlign, children: [
      _ActionBtn(icon: Icons.backspace_outlined, label: 'Erase', onTap: notifier.erase),
      _ModeBtn(
        label: 'Multi-Nums',
        icon: Icons.tag,
        active: mode == EntryMode.fullNumber && multi,
        onTap: () => notifier.setEntryModeAndMulti(EntryMode.fullNumber, true),
      ),
      _ModeBtn(
        label: 'Multi-Crnrs',
        icon: Icons.border_all,
        active: mode == EntryMode.cornerNote && multi,
        onTap: () => notifier.setEntryModeAndMulti(EntryMode.cornerNote, true),
      ),
      _ModeBtn(
        label: 'Multi-Cntrs',
        icon: Icons.control_camera,
        active: mode == EntryMode.centreNote && multi,
        onTap: () => notifier.setEntryModeAndMulti(EntryMode.centreNote, true),
      ),
      _ModeBtn(label: 'Color', icon: Icons.color_lens_outlined, active: isColor,
          onTap: () => notifier.setEntryModeAndMulti(EntryMode.highlighter, false)),
    ]);

    final colorPicker = isColor
        ? <Widget>[
            const SizedBox(height: 4),
            _ColorPickerRow(
                selectedIndex: game.highlightColorIndex,
                onSelect: notifier.setHighlightColor),
          ]
        : <Widget>[];

    if (!expanded) {
      // ── Compact mode (fixed 40px button height) ────────────────────────
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row1, const SizedBox(height: 3),
          row2, const SizedBox(height: 3),
          row3, const SizedBox(height: 3),
          row4,
          ...colorPicker,
        ],
      );
    }

    // ── Expanded mode — every row fills its proportional share of height ──
    return Column(
      children: [
        Expanded(child: row1), const SizedBox(height: 3),
        Expanded(child: row2), const SizedBox(height: 3),
        Expanded(child: row3), const SizedBox(height: 3),
        Expanded(child: row4),
        ...colorPicker,
      ],
    );
  }
}

// ─── Shared primitives ────────────────────────────────────────────────────────

/// A row of exactly 5 `Expanded` items separated by 2 px gaps.
class _ToolRow extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  const _ToolRow({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    assert(children.length == 5);
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(width: 2));
      items.add(Expanded(child: children[i]));
    }
    return Row(crossAxisAlignment: crossAxisAlignment, children: items);
  }
}

/// Base button: min 40 px tall (fills parent height when inside Expanded),
/// rounded, teal when active, white12 when inactive.
class _Btn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool active;

  const _Btn({required this.child, this.onTap, this.onLongPress, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        // minHeight 40 in compact; fills tight constraint from Expanded in expanded mode.
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0D9488) : Colors.white12,
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      ),
    );
  }
}

/// Digit button (1-9). Shows remaining count subscript; greys out when fully placed.
/// Tap: enter digit in current mode. Long-press: smart write or highlight.
class _DigitBtn extends StatelessWidget {
  final int digit;
  final int remaining; // how many of this digit are still unplaced (0–9)
  final bool disabled;
  final void Function(int) onEnter;
  final void Function(int) onLongPress;

  const _DigitBtn({
    required this.digit,
    required this.remaining,
    required this.disabled,
    required this.onEnter,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final fullyPlaced = remaining == 0;
    final effectivelyDisabled = disabled || fullyPlaced;
    return _Btn(
      onTap: effectivelyDisabled ? null : () => onEnter(digit),
      onLongPress: effectivelyDisabled ? null : () => onLongPress(digit),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$digit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: effectivelyDisabled ? Colors.white24 : Colors.white,
            ),
          ),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 10,
              color: effectivelyDisabled ? Colors.white24 : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode button — icon + label, teal when active.
class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Btn(
      active: active,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: active ? Colors.white : Colors.white70),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10, color: active ? Colors.white : Colors.white70),
          ),
        ],
      ),
    );
  }
}

/// Action button (Undo / Redo / Erase / Deselect) — icon + label, always white70.
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Btn(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

/// Compact horizontal color picker (9 colors + ✕ eraser).
class _ColorPickerRow extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;

  const _ColorPickerRow(
      {required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...List.generate(kHighlightColors.length, (i) {
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(kHighlightColors[i]),
                shape: BoxShape.circle,
                border: selectedIndex == i
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => onSelect(-1),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: selectedIndex == -1
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: const Center(
              child: Text('✕', style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }
}
