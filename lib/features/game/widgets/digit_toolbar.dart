import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_state.dart';

class DigitToolbar extends ConsumerWidget {
  const DigitToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Entry mode toggles + multi-select button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ModeButton(
              label: '123',
              icon: Icons.grid_4x4,
              mode: EntryMode.fullNumber,
              currentMode: game.entryMode,
              onTap: () => notifier.setEntryMode(EntryMode.fullNumber),
            ),
            _ModeButton(
              label: 'Corner',
              icon: Icons.format_list_numbered,
              mode: EntryMode.cornerNote,
              currentMode: game.entryMode,
              onTap: () => notifier.setEntryMode(EntryMode.cornerNote),
            ),
            _ModeButton(
              label: 'Centre',
              icon: Icons.notes,
              mode: EntryMode.centreNote,
              currentMode: game.entryMode,
              onTap: () => notifier.setEntryMode(EntryMode.centreNote),
            ),
            _ModeButton(
              label: 'Color',
              icon: Icons.color_lens_outlined,
              mode: EntryMode.highlighter,
              currentMode: game.entryMode,
              onTap: () => notifier.setEntryMode(EntryMode.highlighter),
            ),
            // Multi-select toggle: hidden for highlighter mode
            if (game.entryMode != EntryMode.highlighter)
              _MultiSelectButton(
                active: game.multiSelectMode,
                onTap: notifier.toggleMultiSelect,
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Digit buttons (or color picker for highlighter mode)
        if (game.entryMode == EntryMode.highlighter)
          _ColorPicker(
            selectedIndex: game.highlightColorIndex,
            onSelect: notifier.setHighlightColor,
          )
        else
          _DigitRow(onDigit: notifier.enterDigit),
        const SizedBox(height: 8),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.undo,
              label: 'Undo',
              onTap: notifier.undo,
            ),
            _ActionButton(
              icon: Icons.redo,
              label: 'Redo',
              onTap: notifier.redo,
            ),
            _ActionButton(
              icon: Icons.backspace_outlined,
              label: 'Erase',
              onTap: notifier.erase,
            ),
            _ActionButton(
              icon: Icons.deselect,
              label: 'Deselect',
              onTap: notifier.deselectAll,
            ),
          ],
        ),
      ],
    );
  }
}

class _MultiSelectButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _MultiSelectButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0D9488) : Colors.white12,
          borderRadius: BorderRadius.circular(8),
          border: active
              ? Border.all(color: const Color(0xFF0D9488), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.select_all,
              size: 18,
              color: active ? Colors.white : Colors.white70,
            ),
            Text(
              'Multi',
              style: TextStyle(
                fontSize: 10,
                color: active ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final EntryMode mode;
  final EntryMode currentMode;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.mode,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = mode == currentMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0D9488) : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.white70),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitRow extends StatelessWidget {
  final void Function(int) onDigit;
  const _DigitRow({required this.onDigit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(9, (i) {
        final d = i + 1;
        return GestureDetector(
          onTap: () => onDigit(d),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$d',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;
  const _ColorPicker({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...List.generate(kHighlightColors.length, (i) {
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 32,
              height: 32,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: selectedIndex == -1
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: const Center(
              child: Text('✕', style: TextStyle(color: Colors.red, fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
