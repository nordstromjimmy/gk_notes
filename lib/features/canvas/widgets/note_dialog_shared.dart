import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Shared input decoration for create and edit dialogs.
InputDecoration fieldDecoration(
  String label, {
  String? hint,
  bool alignLabel = false,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  alignLabelWithHint: alignLabel,
  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.22)),
  filled: true,
  fillColor: const Color(0xFF1A2530),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colors.blueGrey, width: 1.5),
  ),
);

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
  );
}

class NoteColorSwatch extends StatelessWidget {
  const NoteColorSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 7,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
            : null,
      ),
    );
  }
}

class MediaSection extends StatelessWidget {
  const MediaSection({
    super.key,
    required this.label,
    required this.icon,
    required this.onAdd,
    required this.child,
  });

  final String label;
  final IconData icon;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel(label),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(icon, size: 14),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class ChipList extends StatelessWidget {
  const ChipList({super.key, required this.items, required this.onRemove});

  final List<String> items;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Chip(
          label: Text(
            p.basename(items[i]),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          backgroundColor: const Color(0xFF1A2530),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          deleteIcon: Icon(
            Icons.close,
            size: 14,
            color: Colors.white.withValues(alpha: 0.45),
          ),
          onDeleted: () => onRemove(i),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );
  }
}

class RemoveBadge extends StatelessWidget {
  const RemoveBadge({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 12, color: Colors.white),
      ),
    );
  }
}
