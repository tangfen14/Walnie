import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/parse_voice_command_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/presentation/controllers/home_controller.dart';
import 'package:baby_tracker/presentation/controllers/home_state.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme_extensions.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:baby_tracker/presentation/utils/voice_payload_mapper.dart';
import 'package:baby_tracker/presentation/widgets/event_editor_sheet.dart';
import 'package:baby_tracker/presentation/widgets/summary_card.dart';
import 'package:baby_tracker/presentation/widgets/voice_recording_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeControllerProvider);
    final parserUseCase = ref.read(parseVoiceCommandUseCaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walnie'),
        actions: [
          IconButton(
            onPressed: () => _showIntervalSelector(context, ref),
            icon: const Icon(Icons.alarm),
            tooltip: '喂奶提醒间隔',
          ),
        ],
      ),
      body: homeStateAsync.when(
        data: (state) => _HomeContent(
          state: state,
          onAddEvent: (type) =>
              _openEventEditor(context, ref, initialType: type),
          onEditEvent: (event) => _openEventEditor(
            context,
            ref,
            initialType: event.type,
            initialEvent: event,
          ),
          onSelectFilter: (type) {
            final nextType = state.filterType == type ? null : type;
            ref.read(homeControllerProvider.notifier).setFilter(nextType);
          },
          onRefresh: () =>
              ref.read(homeControllerProvider.notifier).refreshData(),
          onOpenReminderSettings: () => _showIntervalSelector(context, ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(WalnieTokens.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败：$error'),
                const SizedBox(height: WalnieTokens.spacingSm),
                FilledButton(
                  onPressed: () =>
                      ref.read(homeControllerProvider.notifier).refreshData(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WalnieTokens.spacingLg,
            0,
            WalnieTokens.spacingLg,
            WalnieTokens.spacingLg,
          ),
          child: _VoiceActionBar(
            onVoiceTap: () => _handleVoiceCommand(context, ref),
            onTextTap: () => _showTextInputDialog(context, ref, parserUseCase),
          ),
        ),
      ),
    );
  }

  Future<void> _showIntervalSelector(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = ref.read(homeControllerProvider).value;
    final current = state?.intervalHours ?? 3;

    final value = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(WalnieTokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('喂奶提醒间隔', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: WalnieTokens.spacingMd),
                Wrap(
                  spacing: WalnieTokens.spacingSm,
                  runSpacing: WalnieTokens.spacingSm,
                  children: List<Widget>.generate(6, (index) {
                    final hour = index + 1;
                    final selected = hour == current;
                    return ChoiceChip(
                      label: Text('$hour 小时'),
                      selected: selected,
                      onSelected: (_) => Navigator.of(context).pop(hour),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (value == null) {
      return;
    }

    await ref
        .read(homeControllerProvider.notifier)
        .updateReminderInterval(value);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提醒间隔已更新为 $value 小时')));
    }
  }

  Future<void> _openEventEditor(
    BuildContext context,
    WidgetRef ref, {
    required EventType initialType,
    BabyEvent? initialEvent,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EventEditorSheet(
          initialType: initialType,
          initialEvent: initialEvent,
          onSubmit: (event) {
            return ref.read(homeControllerProvider.notifier).addEvent(event);
          },
          onDelete: initialEvent == null
              ? null
              : (event) {
                  return ref
                      .read(homeControllerProvider.notifier)
                      .deleteEvent(event);
                },
        );
      },
    );
  }

  Future<void> _handleVoiceCommand(BuildContext context, WidgetRef ref) async {
    final parserUseCase = ref.read(parseVoiceCommandUseCaseProvider);

    final action = await showVoiceRecordingSheet(context);

    if (action == null || !context.mounted) {
      return;
    }

    switch (action.action) {
      case VoiceRecordingAction.cancel:
        return;
      case VoiceRecordingAction.toText:
        _showTextInputDialog(
          context,
          ref,
          parserUseCase,
          initialText: action.transcript,
        );
        return;
      case VoiceRecordingAction.proceed:
        break;
    }

    final transcript = action.transcript.trim();
    if (transcript.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有识别到有效语音，请再试一次')));
      return;
    }

    final cancellationToken = VoiceParseCancellationToken();

    try {
      _showVoiceProgress(
        context,
        '语音已发送，正在匹配本地规则...',
        onCancel: () {
          cancellationToken.cancel();
          _clearVoiceProgress(context);
        },
      );
      final intent = await parserUseCase.fromTranscript(
        transcript,
        cancellationToken: cancellationToken,
        onProgress: (progress) {
          if (!context.mounted || cancellationToken.isCancelled) {
            return;
          }
          _showVoiceProgress(
            context,
            _voiceProgressText(progress),
            onCancel: () {
              cancellationToken.cancel();
              _clearVoiceProgress(context);
            },
          );
        },
      );

      if (!context.mounted || cancellationToken.isCancelled) {
        return;
      }
      _clearVoiceProgress(context);

      switch (intent.intentType) {
        case VoiceIntentType.createEvent:
          await _handleCreateEventIntent(context, ref, transcript, intent);
          break;
        case VoiceIntentType.setReminder:
          await _handleSetReminderIntent(context, ref, intent);
          break;
        case VoiceIntentType.querySummary:
          await _handleQueryIntent(context, ref, intent);
          break;
        case VoiceIntentType.unknown:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法解析：$transcript\n请换一种说法或手动记录。')),
          );
          break;
      }
    } catch (error) {
      if (context.mounted) {
        _clearVoiceProgress(context);
        if (error is VoiceParseCancelledException) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('语音处理失败：$error')));
      }
    }
  }

  Future<void> _showTextInputDialog(
    BuildContext context,
    WidgetRef ref,
    ParseVoiceCommandUseCase parserUseCase, {
    String initialText = '',
  }) async {
    final controller = TextEditingController(text: initialText);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('输入指令'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '例如：记录吃奶 20分钟'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }

    if (result == null || result.isEmpty || !context.mounted) {
      return;
    }

    final cancellationToken = VoiceParseCancellationToken();

    try {
      _showVoiceProgress(
        context,
        '正在匹配本地规则...',
        onCancel: () {
          cancellationToken.cancel();
          _clearVoiceProgress(context);
        },
      );
      final intent = await parserUseCase.fromTranscript(
        result,
        cancellationToken: cancellationToken,
        onProgress: (progress) {
          if (!context.mounted || cancellationToken.isCancelled) {
            return;
          }
          _showVoiceProgress(
            context,
            _voiceProgressText(progress),
            onCancel: () {
              cancellationToken.cancel();
              _clearVoiceProgress(context);
            },
          );
        },
      );

      if (!context.mounted || cancellationToken.isCancelled) {
        return;
      }
      _clearVoiceProgress(context);

      switch (intent.intentType) {
        case VoiceIntentType.createEvent:
          await _handleCreateEventIntent(context, ref, result, intent);
          break;
        case VoiceIntentType.setReminder:
          await _handleSetReminderIntent(context, ref, intent);
          break;
        case VoiceIntentType.querySummary:
          await _handleQueryIntent(context, ref, intent);
          break;
        case VoiceIntentType.unknown:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('无法解析：$result\n请换一种说法或手动记录。')));
          break;
      }
    } catch (error) {
      if (context.mounted) {
        _clearVoiceProgress(context);
        if (error is VoiceParseCancelledException) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('处理失败：$error')));
      }
    }
  }

  String _voiceProgressText(VoiceParseProgress progress) {
    switch (progress) {
      case VoiceParseProgress.ruleMatching:
        return '正在匹配本地规则...';
      case VoiceParseProgress.ruleMatched:
        return '命中本地规则，正在生成结果...';
      case VoiceParseProgress.fallbackToLlm:
        return '本地规则未命中，正在调用大模型...';
      case VoiceParseProgress.llmMatched:
        return '大模型解析完成，正在生成结果...';
      case VoiceParseProgress.unknown:
        return '未识别到明确意图，正在整理结果...';
    }
  }

  void _showVoiceProgress(
    BuildContext context,
    String message, {
    VoidCallback? onCancel,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 1),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: WalnieTokens.spacingSm),
            Expanded(child: Text(message)),
          ],
        ),
        action: onCancel == null
            ? null
            : SnackBarAction(label: '取消', onPressed: onCancel),
      ),
    );
  }

  void _clearVoiceProgress(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Future<void> _handleCreateEventIntent(
    BuildContext context,
    WidgetRef ref,
    String transcript,
    VoiceIntent intent,
  ) async {
    final initialEvent = eventFromVoiceIntent(intent);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EventEditorSheet(
          initialType: initialEvent.type,
          initialEvent: initialEvent,
          headerText: transcript,
          onSubmit: (event) {
            return ref.read(homeControllerProvider.notifier).addEvent(event);
          },
        );
      },
    );
  }

  Future<void> _handleSetReminderIntent(
    BuildContext context,
    WidgetRef ref,
    VoiceIntent intent,
  ) async {
    final interval = (intent.payload['intervalHours'] as num?)?.toInt() ?? 3;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认提醒设置'),
          content: Text('设置喂奶提醒间隔为 $interval 小时？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(homeControllerProvider.notifier)
        .updateReminderInterval(interval.clamp(1, 6));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('提醒设置已更新')));
    }
  }

  Future<void> _handleQueryIntent(
    BuildContext context,
    WidgetRef ref,
    VoiceIntent intent,
  ) async {
    final answer = await ref
        .read(homeControllerProvider.notifier)
        .answerQuery(intent);

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('语音问答结果'),
          content: Text(answer),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceActionBar extends StatelessWidget {
  const _VoiceActionBar({required this.onVoiceTap, required this.onTextTap});

  final VoidCallback onVoiceTap;
  final VoidCallback onTextTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(WalnieTokens.spacingSm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Semantics(
              button: true,
              label: '语音录入',
              child: FilledButton.icon(
                onPressed: onVoiceTap,
                icon: const Icon(Icons.mic_rounded),
                label: const Text('语音录入'),
              ),
            ),
          ),
          const SizedBox(width: WalnieTokens.spacingSm),
          Expanded(
            flex: 2,
            child: Semantics(
              button: true,
              label: '文字输入',
              child: OutlinedButton.icon(
                onPressed: onTextTap,
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('文字'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.state,
    required this.onAddEvent,
    required this.onEditEvent,
    required this.onSelectFilter,
    required this.onRefresh,
    required this.onOpenReminderSettings,
  });

  final HomeState state;
  final void Function(EventType type) onAddEvent;
  final void Function(BabyEvent event) onEditEvent;
  final void Function(EventType type) onSelectFilter;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenReminderSettings;

  @override
  Widget build(BuildContext context) {
    final summaryItems = _summaryItems(state);
    final firstRowItems = summaryItems.take(3).toList(growable: false);
    final secondRowItems = summaryItems.skip(3).toList(growable: false);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          WalnieTokens.spacingLg,
          WalnieTokens.spacingLg,
          WalnieTokens.spacingLg,
          WalnieTokens.spacing2xl,
        ),
        children: [
          _BrandHeader(
            state: state,
            onOpenReminderSettings: onOpenReminderSettings,
          ),
          const SizedBox(height: WalnieTokens.spacingLg),
          _SectionHeader(
            title: '今日概览',
            subtitle: state.filterType == null
                ? '点击卡片可筛选时间线'
                : '当前筛选：${state.filterType!.labelZh}',
          ),
          const SizedBox(height: WalnieTokens.spacingSm),
          _SummaryOverviewRows(
            firstRowItems: firstRowItems,
            secondRowItems: secondRowItems,
            selectedType: state.filterType,
            onSelectFilter: onSelectFilter,
          ),
          const SizedBox(height: WalnieTokens.spacingLg),
          const _SectionHeader(title: '快速记录', subtitle: '主操作优先展示，减少录入路径'),
          const SizedBox(height: WalnieTokens.spacingSm),
          _QuickActions(onAddEvent: onAddEvent),
          const SizedBox(height: WalnieTokens.spacingXl),
          _SectionHeader(
            title: _timelineTitle(state.filterType),
            subtitle: '按天分组，点击可编辑',
          ),
          const SizedBox(height: WalnieTokens.spacingSm),
          if (state.timeline.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(WalnieTokens.spacingXl),
                child: Text(
                  '暂无记录，先新增一条吧。',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            ..._groupEventsByDay(state.timeline).asMap().entries.map(
              (entry) => _TimelineDaySection(
                group: entry.value,
                showRelativeOnFirst: entry.key == 0,
                onTapEvent: onEditEvent,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryOverviewRows extends StatelessWidget {
  const _SummaryOverviewRows({
    required this.firstRowItems,
    required this.secondRowItems,
    required this.selectedType,
    required this.onSelectFilter,
  });

  final List<_SummaryItem> firstRowItems;
  final List<_SummaryItem> secondRowItems;
  final EventType? selectedType;
  final void Function(EventType type) onSelectFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryOverviewRow(
          items: firstRowItems,
          selectedType: selectedType,
          onSelectFilter: onSelectFilter,
        ),
        if (secondRowItems.isNotEmpty) ...[
          const SizedBox(height: WalnieTokens.spacingSm),
          _SummaryOverviewRow(
            items: secondRowItems,
            selectedType: selectedType,
            onSelectFilter: onSelectFilter,
          ),
        ],
      ],
    );
  }
}

class _SummaryOverviewRow extends StatelessWidget {
  const _SummaryOverviewRow({
    required this.items,
    required this.selectedType,
    required this.onSelectFilter,
  });

  final List<_SummaryItem> items;
  final EventType? selectedType;
  final void Function(EventType type) onSelectFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: WalnieTokens.spacingSm),
            Expanded(
              child: SummaryCard(
                title: items[i].title,
                value: items[i].value,
                icon: items[i].icon,
                accentColor: _accentColor(context, items[i].type),
                selected: selectedType == items[i].type,
                onTap: () => onSelectFilter(items[i].type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleLarge),
        const SizedBox(height: WalnieTokens.spacingXs),
        Text(subtitle, style: textTheme.bodyMedium),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.state,
    required this.onOpenReminderSettings,
  });

  final HomeState state;
  final VoidCallback onOpenReminderSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final todayTotal =
        state.todaySummary.feedCount +
        state.todaySummary.poopCount +
        state.todaySummary.peeCount +
        state.todaySummary.diaperCount +
        state.todaySummary.pumpCount;

    return Container(
      padding: const EdgeInsets.all(WalnieTokens.spacingLg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primaryContainer, colorScheme.surface],
        ),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Walnie', style: theme.textTheme.headlineSmall),
          const SizedBox(height: WalnieTokens.spacingXs),
          Text('今天累计记录 $todayTotal 条', style: theme.textTheme.bodyLarge),
          const SizedBox(height: WalnieTokens.spacingLg),
          Container(
            padding: const EdgeInsets.all(WalnieTokens.spacingMd),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.alarm, color: colorScheme.primary),
                const SizedBox(width: WalnieTokens.spacingSm),
                Expanded(
                  child: Text(
                    state.nextReminderAt == null
                        ? '下次提醒：暂无（先记录一条喂奶）'
                        : '下次提醒：${DateFormat('MM-dd HH:mm').format(state.nextReminderAt!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: onOpenReminderSettings,
                  child: const Text('设置'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAddEvent});

  final void Function(EventType type) onAddEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onAddEvent(EventType.feed),
                icon: const Icon(Icons.local_drink),
                label: const Text('记录吃奶'),
              ),
            ),
            const SizedBox(width: WalnieTokens.spacingSm),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onAddEvent(EventType.pump),
                icon: const Icon(Icons.science),
                label: const Text('记录吸奶'),
              ),
            ),
          ],
        ),
        const SizedBox(height: WalnieTokens.spacingSm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onAddEvent(EventType.poop),
                icon: const Icon(Icons.baby_changing_station),
                label: const Text('便便'),
              ),
            ),
            const SizedBox(width: WalnieTokens.spacingSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onAddEvent(EventType.pee),
                icon: const Icon(Icons.water_drop),
                label: const Text('尿尿'),
              ),
            ),
            const SizedBox(width: WalnieTokens.spacingSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onAddEvent(EventType.diaper),
                icon: const Icon(Icons.checkroom),
                label: const Text('换尿布'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
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

List<_SummaryItem> _summaryItems(HomeState state) {
  return [
    _SummaryItem(
      type: EventType.feed,
      title: '吃奶',
      value: '${state.todaySummary.feedCount}',
      icon: Icons.local_drink,
    ),
    _SummaryItem(
      type: EventType.poop,
      title: '便便',
      value: '${state.todaySummary.poopCount}',
      icon: Icons.baby_changing_station,
    ),
    _SummaryItem(
      type: EventType.pee,
      title: '尿尿',
      value: '${state.todaySummary.peeCount}',
      icon: Icons.water_drop,
    ),
    _SummaryItem(
      type: EventType.diaper,
      title: '换尿布',
      value: '${state.todaySummary.diaperCount}',
      icon: Icons.checkroom,
    ),
    _SummaryItem(
      type: EventType.pump,
      title: '吸奶',
      value: '${state.todaySummary.pumpCount}',
      icon: Icons.science,
    ),
  ];
}

class _TimelineDaySection extends StatelessWidget {
  const _TimelineDaySection({
    required this.group,
    required this.onTapEvent,
    required this.showRelativeOnFirst,
  });

  final _TimelineDayGroup group;
  final void Function(BabyEvent event) onTapEvent;
  final bool showRelativeOnFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeline = theme.timelineColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: WalnieTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dayLabel(group.dayStart), style: theme.textTheme.titleMedium),
          const SizedBox(height: WalnieTokens.spacingSm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(WalnieTokens.spacingMd),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: timeline.groupDot,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: WalnieTokens.spacingSm),
                      Text(
                        _groupSummaryLabel(group.events),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WalnieTokens.spacingSm),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: WalnieTokens.spacingXs),
                  ...group.events.asMap().entries.map((entry) {
                    return _TimelineTrackItem(
                      event: entry.value,
                      isLast: entry.key == group.events.length - 1,
                      showRelative: showRelativeOnFirst && entry.key == 0,
                      onTap: () => onTapEvent(entry.value),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTrackItem extends StatelessWidget {
  const _TimelineTrackItem({
    required this.event,
    required this.isLast,
    required this.showRelative,
    required this.onTap,
  });

  final BabyEvent event;
  final bool isLast;
  final bool showRelative;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeline = theme.timelineColors;
    final accent = _accentColor(context, event.type);

    return Semantics(
      button: true,
      label:
          '${event.type.labelZh}，${DateFormat('HH:mm').format(event.occurredAt)}，${_subtitleFor(event)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: WalnieTokens.spacingSm),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 48,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      DateFormat('HH:mm').format(event.occurredAt),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(width: WalnieTokens.spacingSm),
                SizedBox(
                  width: 18,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            margin: const EdgeInsets.only(top: 6),
                            color: timeline.trackLine,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: WalnieTokens.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconFor(event.type), size: 18, color: accent),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: Text(
                              event.type.labelZh,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            _primaryMetric(event),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: WalnieTokens.spacingXs),
                      Text(
                        _subtitleFor(event),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (showRelative) ...[
                        const SizedBox(height: WalnieTokens.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WalnieTokens.spacingSm,
                            vertical: WalnieTokens.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: timeline.relativeChipBackground,
                            borderRadius: BorderRadius.circular(
                              WalnieTokens.radiusSm,
                            ),
                          ),
                          child: Text(
                            _relativeText(event.occurredAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: timeline.relativeChipForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _TimelineDayGroup {
  _TimelineDayGroup({required this.dayStart, required this.events});

  final DateTime dayStart;
  final List<BabyEvent> events;
}

IconData _iconFor(EventType type) {
  switch (type) {
    case EventType.feed:
      return Icons.local_drink;
    case EventType.poop:
      return Icons.baby_changing_station;
    case EventType.pee:
      return Icons.water_drop;
    case EventType.diaper:
      return Icons.checkroom;
    case EventType.pump:
      return Icons.science;
  }
}

Color _accentColor(BuildContext context, EventType type) {
  final colors = Theme.of(context).timelineColors;
  switch (type) {
    case EventType.feed:
      return colors.feed;
    case EventType.poop:
      return colors.poop;
    case EventType.pee:
      return colors.pee;
    case EventType.diaper:
      return colors.diaper;
    case EventType.pump:
      return colors.pump;
  }
}

List<_TimelineDayGroup> _groupEventsByDay(List<BabyEvent> events) {
  final groups = <_TimelineDayGroup>[];
  for (final event in events) {
    final day = DateTime(
      event.occurredAt.year,
      event.occurredAt.month,
      event.occurredAt.day,
    );
    if (groups.isEmpty || !_isSameDay(groups.last.dayStart, day)) {
      groups.add(_TimelineDayGroup(dayStart: day, events: [event]));
      continue;
    }
    groups.last.events.add(event);
  }
  return groups;
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (_isSameDay(day, today)) {
    return '今天';
  }
  if (_isSameDay(day, yesterday)) {
    return '昨天';
  }
  return DateFormat('M月d日').format(day);
}

String _groupSummaryLabel(List<BabyEvent> events) {
  final count = events.length;
  if (count == 0) {
    return '无记录';
  }
  final firstType = events.first.type;
  final allSameType = events.every((item) => item.type == firstType);
  if (allSameType) {
    return '${firstType.labelZh} $count 次';
  }
  return '全部记录 $count 条';
}

String _primaryMetric(BabyEvent event) {
  if (event.amountMl != null) {
    return '${event.amountMl}ml';
  }
  if (event.durationMin != null) {
    return '${event.durationMin}分钟';
  }
  return '--';
}

String _relativeText(DateTime time) {
  final now = DateTime.now();
  var diff = now.difference(time);
  if (diff.isNegative) {
    diff = Duration.zero;
  }

  if (diff.inMinutes < 1) {
    return '刚刚';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}分钟前';
  }
  if (diff.inDays < 1) {
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) {
      return '$hours小时前';
    }
    return '$hours小时$minutes分钟前';
  }
  return '${diff.inDays}天前';
}

String _subtitleFor(BabyEvent event) {
  if (event.type == EventType.feed) {
    final chunks = <String>[];
    if (event.feedMethod != null) {
      chunks.add(event.feedMethod!.labelZh);
    }
    if (event.durationMin != null) {
      chunks.add('${event.durationMin} 分钟');
    }
    if (event.amountMl != null) {
      chunks.add('${event.amountMl} ml');
    }
    if (event.note != null && event.note!.isNotEmpty) {
      chunks.add(event.note!);
    }
    return chunks.isEmpty ? '无附加信息' : chunks.join(' · ');
  }

  if (event.type == EventType.pump) {
    final chunks = <String>[];
    if (event.pumpStartAt != null && event.pumpEndAt != null) {
      chunks.add(
        '${DateFormat('HH:mm').format(event.pumpStartAt!)}-${DateFormat('HH:mm').format(event.pumpEndAt!)}',
      );
    }
    if (event.amountMl != null) {
      chunks.add('${event.amountMl} ml');
    }
    if (event.note != null && event.note!.isNotEmpty) {
      chunks.add(event.note!);
    }
    return chunks.isEmpty ? '无附加信息' : chunks.join(' · ');
  }

  if (event.note == null || event.note!.isEmpty) {
    return '无备注';
  }
  return event.note ?? '无备注';
}

String _timelineTitle(EventType? filterType) {
  if (filterType == null) {
    return '时间线';
  }
  return '${filterType.labelZh} · 时间线';
}
