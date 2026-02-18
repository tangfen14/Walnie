import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.selected = false,
    this.expand = true,
    this.compact = false,
    this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool expand;
  final bool compact;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = selected
        ? colorScheme.primaryContainer
        : Colors.white;
    final iconColor = colorScheme.primary;
    final valueColor = selected
        ? colorScheme.onPrimaryContainer
        : Theme.of(context).textTheme.titleLarge?.color;
    final titleColor = selected
        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.82)
        : Colors.black54;

    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: compact ? 18 : 20, color: iconColor),
            SizedBox(height: compact ? 6 : 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 18 : null,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: compact ? 14 : null,
                color: titleColor,
              ),
            ),
          ],
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: card);
    }

    if (!expand) {
      return card;
    }

    return Expanded(child: card);
  }
}
