import 'package:baby_tracker/presentation/theme/walnie_theme_extensions.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.selected = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final motion = theme.motionTokens;

    final background = selected
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final borderColor = selected ? accentColor : colorScheme.outlineVariant;
    final iconBackground = accentColor.withValues(
      alpha: selected ? 0.24 : 0.16,
    );
    final valueColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final titleColor = selected
        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
        : theme.textTheme.bodyMedium?.color;

    return Semantics(
      button: onTap != null,
      label: '$title，$value',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
          child: AnimatedContainer(
            duration: motion.normal,
            curve: motion.enterCurve,
            padding: const EdgeInsets.all(WalnieTokens.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.light
                      ? WalnieTokens.shadowColor.withValues(alpha: 0.08)
                      : colorScheme.surface.withValues(alpha: 0),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(WalnieTokens.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const Spacer(),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: WalnieTokens.spacingXs),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
