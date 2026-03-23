import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_state.dart';

// Compact 4-row grid layout — never overflows in portrait or landscape:
//
//   Row 1:  [Undo]     [1] [2] [3]  [Num]
//   Row 2:  [Redo]     [4] [5] [6]  [Corner]
//   Row 3:  [Deselect] [7] [8] [9]  [Centre]
//   Row 4:  [Erase] [M·Num] [M·Cor] [M·Cen] [Color]
//   Row 5:  (compact color-picker — only visible in Color mode)
//
// Each row uses 5 Expanded children separated by 2 px gaps.
// All buttons are exactly 40 px tall; text labels use 8-9 px font.

class DigitToolbar extends ConsumerWidget {
  const DigitToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final mode = game.entryMode;
    final multi = game.multiSelectMode;
    final isColor = mode == EntryMode.highlighter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Row 1: Undo | 1 | 2 | 3 | Num (single mode) ──────────────────
        _ToolRow(children: [
          _ActionBtn(icon: Icons.undo, label: 'Undo', onTap: notifier.undo),
          _DigitBtn(digit: 1, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _DigitBtn(digit: 2, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _DigitBtn(digit: 3, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _ModeBtn(
            label: 'Num',
            icon: Icons.grid_4x4,
            active: mode == EntryMode.fullNumber && !multi,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.fullNumber, false),
          ),
        ]),
        const SizedBox(height: 3),
        // ── Row 2: Redo | 4 | 5 | 6 | Corner (single mode) ───────────────
        _ToolRow(children: [
          _ActionBtn(icon: Icons.redo, label: 'Redo', onTap: notifier.redo),
          _DigitBtn(digit: 4, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _DigitBtn(digit: 5, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _DigitBtn(digit: 6, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _ModeBtn(
            label: 'Corner',
            icon: Icons.format_list_numbered,
            active: mode == EntryMode.cornerNote && !multi,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.cornerNote, false),
          ),
        ]),
        const SizedBox(height: 3),
        // ── Row 3: Deselect | 7 | 8 | 9 | Centre (single mode) ───────────
        _ToolRow(children: [
          _ActionBtn(icon: Icons.deselect, label: 'Desel', onTap: notifier.deselectAll),
          _DigitBtn(digit: 7, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _DigitBtn(digit: 8, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _DigitBtn(digit: 9, disabled: isColor, onEnter: notifier.enterDigit, onLongPress: notifier.longPressDigit),
          _ModeBtn(
            label: 'Centre',
            icon: Icons.notes,
            active: mode == EntryMode.centreNote && !multi,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.centreNote, false),
          ),
        ]),
        const SizedBox(height: 3),
        // ── Row 4: Erase | M·Num | M·Cor | M·Cen | Color ─────────────────
        _ToolRow(children: [
          _ActionBtn(
              icon: Icons.backspace_outlined, label: 'Erase', onTap: notifier.erase),
          _ModeBtn(
            label: 'M·Num',
            icon: Icons.select_all,
            active: mode == EntryMode.fullNumber && multi,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.fullNumber, true),
          ),
          _ModeBtn(
            label: 'M·Cor',
            icon: Icons.select_all,
            active: mode == EntryMode.cornerNote && multi,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.cornerNote, true),
          ),
          _ModeBtn(
            label: 'M·Cen',
            icon: Icons.select_all,
            active: mode == EntryMode.centreNote && multi,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.centreNote, true),
          ),
          _ModeBtn(
            label: 'Color',
            icon: Icons.color_lens_outlined,
            active: isColor,
            onTap: () => notifier.setEntryModeAndMulti(EntryMode.highlighter, false),
          ),
        ]),
        // ── Row 5: compact color picker (only in Color mode) ───────────────
        if (isColor) ...[
          const SizedBox(height: 4),
          _ColorPickerRow(
            selectedIndex: game.highlightColorIndex,
            onSelect: notifier.setHighlightColor,
          ),
        ],
      ],
    );
  }
}

// ─── Shared primitives ────────────────────────────────────────────────────────

/// A row of exactly 5 `Expanded` items separated by 2 px gaps.
class _ToolRow extends StatelessWidget {
  final List<Widget> children;
  const _ToolRow({required this.children});

  @override
  Widget build(BuildContext context) {
    assert(children.length == 5);
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) items.add(const SizedBox(width: 2));
      items.add(Expanded(child: children[i]));
    }
    return Row(children: items);
  }
}

/// Base button: 40 px tall, rounded, teal when active, white12 when inactive.
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
        height: 40,
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

/// Digit button (1-9). Grayed out and non-interactive in Color mode.
/// Tap: enter digit in current mode. Long-press: smart write or highlight.
class _DigitBtn extends StatelessWidget {
  final int digit;
  final bool disabled;
  final void Function(int) onEnter;
  final void Function(int) onLongPress;

  const _DigitBtn({
    required this.digit,
    required this.disabled,
    required this.onEnter,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return _Btn(
      onTap: disabled ? null : () => onEnter(digit),
      onLongPress: disabled ? null : () => onLongPress(digit),
      child: Text(
        '$digit',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: disabled ? Colors.white24 : Colors.white,
        ),
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
          Icon(icon, size: 13, color: active ? Colors.white : Colors.white70),
          Text(
            label,
            style: TextStyle(
                fontSize: 8, color: active ? Colors.white : Colors.white70),
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
          Icon(icon, size: 15, color: Colors.white70),
          Text(label,
              style: const TextStyle(fontSize: 8, color: Colors.white70)),
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
