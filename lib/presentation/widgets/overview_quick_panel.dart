import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:flutter/material.dart';

class OverviewQuickItem {
  const OverviewQuickItem({
    required this.type,
    required this.title,
    required this.value,
    required this.icon,
  });

  final EventType type;
  final String title;
  final String value;
  final IconData icon;
}

class OverviewQuickPanel extends StatelessWidget {
  const OverviewQuickPanel({
    super.key,
    required this.items,
    required this.selectedType,
    required this.onSelectFilter,
    required this.onAddEvent,
  });

  final List<OverviewQuickItem> items;
  final EventType? selectedType;
  final void Function(EventType type) onSelectFilter;
  final void Function(EventType type) onAddEvent;

  @override
  Widget build(BuildContext context) {
    final firstRowItems = items.take(3).toList(growable: false);
    final secondRowItems = items.skip(3).toList(growable: false);

    return Column(
      children: [
        _OverviewQuickRow(
          items: firstRowItems,
          selectedType: selectedType,
          onSelectFilter: onSelectFilter,
          onAddEvent: onAddEvent,
        ),
        if (secondRowItems.isNotEmpty) ...[
          const SizedBox(height: WalnieTokens.spacingSm),
          _OverviewQuickRow(
            items: secondRowItems,
            selectedType: selectedType,
            onSelectFilter: onSelectFilter,
            onAddEvent: onAddEvent,
          ),
        ],
      ],
    );
  }
}

class _OverviewQuickRow extends StatelessWidget {
  const _OverviewQuickRow({
    required this.items,
    required this.selectedType,
    required this.onSelectFilter,
    required this.onAddEvent,
  });

  final List<OverviewQuickItem> items;
  final EventType? selectedType;
  final void Function(EventType type) onSelectFilter;
  final void Function(EventType type) onAddEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: WalnieTokens.spacingSm),
            Expanded(
              child: _SummaryQuickCard(
                item: items[i],
                selected: selectedType == items[i].type,
                onSelectFilter: () => onSelectFilter(items[i].type),
                onAddEvent: () => onAddEvent(items[i].type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryQuickCard extends StatelessWidget {
  const _SummaryQuickCard({
    required this.item,
    required this.selected,
    required this.onSelectFilter,
    required this.onAddEvent,
  });

  final OverviewQuickItem item;
  final bool selected;
  final VoidCallback onSelectFilter;
  final VoidCallback onAddEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(context, item.type);
    final background = selected
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final borderColor = selected ? accent : colorScheme.outlineVariant;
    final iconBackground = accent.withValues(alpha: selected ? 0.24 : 0.16);

    return Semantics(
      key: ValueKey('overview-card-${item.type.name}'),
      selected: selected,
      label: '${item.title}，${item.value}',
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
          border: Border.all(color: borderColor),
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
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('overview-filter-${item.type.name}'),
                  onTap: onSelectFilter,
                  borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(WalnieTokens.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(
                              WalnieTokens.radiusSm,
                            ),
                          ),
                          child: Icon(item.icon, size: 18, color: accent),
                        ),
                        const Spacer(),
                        Text(
                          item.value,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: selected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: WalnieTokens.spacingXs),
                        Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: selected
                                ? colorScheme.onPrimaryContainer.withValues(
                                    alpha: 0.8,
                                  )
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WalnieTokens.spacingSm,
                0,
                WalnieTokens.spacingSm,
                WalnieTokens.spacingSm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: ValueKey('overview-record-${item.type.name}'),
                  onPressed: onAddEvent,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('记录'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _accentColor(BuildContext context, EventType type) {
  final colorScheme = Theme.of(context).colorScheme;
  switch (type) {
    case EventType.feed:
      return colorScheme.primary;
    case EventType.poop:
      return colorScheme.secondary;
    case EventType.pee:
      return colorScheme.tertiary;
    case EventType.diaper:
      return colorScheme.secondary;
    case EventType.pump:
      return colorScheme.primary;
  }
}
