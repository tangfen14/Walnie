import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/parse_voice_command_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/presentation/controllers/home_controller.dart';
import 'package:baby_tracker/presentation/controllers/home_state.dart';
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
    final voiceButtonWidth = (MediaQuery.sizeOf(context).width - 64).clamp(
      220.0,
      360.0,
    );

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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败：$error'),
                const SizedBox(height: 10),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onLongPressStart: (_) => _handleVoiceCommand(context, ref),
        child: SizedBox(
          width: voiceButtonWidth.toDouble(),
          child: FloatingActionButton.extended(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('按住按钮开始语音识别')));
            },
            icon: const Icon(Icons.mic),
            label: const Text('按住说话'),
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
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('喂奶提醒间隔', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
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
      showDragHandle: true,
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

    if (action == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    switch (action.action) {
      case VoiceRecordingAction.cancel:
        return;
      case VoiceRecordingAction.toText:
        _showTextInputDialog(context, ref, parserUseCase);
        return;
      case VoiceRecordingAction.proceed:
        break;
    }

    final transcript = action.transcript.trim();
    if (transcript.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有识别到有效语音，请再试一次')));
      }
      return;
    }

    try {
      _showVoiceProgress(context, '语音已发送，正在匹配本地规则...');
      final intent = await parserUseCase.fromTranscript(
        transcript,
        onProgress: (progress) {
          if (!context.mounted) {
            return;
          }
          _showVoiceProgress(context, _voiceProgressText(progress));
        },
      );

      if (!context.mounted) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('语音处理失败：$error')));
      }
    }
  }

  Future<void> _showTextInputDialog(
    BuildContext context,
    WidgetRef ref,
    ParseVoiceCommandUseCase parserUseCase,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('输入指令'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '例如：记录吃奶 20分钟',
              border: OutlineInputBorder(),
            ),
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

    if (result == null || result.isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    try {
      _showVoiceProgress(context, '正在匹配本地规则...');
      final intent = await parserUseCase.fromTranscript(
        result,
        onProgress: (progress) {
          if (!context.mounted) {
            return;
          }
          _showVoiceProgress(context, _voiceProgressText(progress));
        },
      );

      if (!context.mounted) {
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

  void _showVoiceProgress(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 1),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
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
      showDragHandle: true,
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

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.state,
    required this.onAddEvent,
    required this.onEditEvent,
    required this.onSelectFilter,
    required this.onRefresh,
  });

  final HomeState state;
  final void Function(EventType type) onAddEvent;
  final void Function(BabyEvent event) onEditEvent;
  final void Function(EventType type) onSelectFilter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              SummaryCard(
                title: '吃奶',
                value: '${state.todaySummary.feedCount}',
                icon: Icons.local_drink,
                selected: state.filterType == EventType.feed,
                onTap: () => onSelectFilter(EventType.feed),
                compact: true,
              ),
              const SizedBox(width: 8),
              SummaryCard(
                title: '便便',
                value: '${state.todaySummary.poopCount}',
                icon: Icons.baby_changing_station,
                selected: state.filterType == EventType.poop,
                onTap: () => onSelectFilter(EventType.poop),
                compact: true,
              ),
              const SizedBox(width: 8),
              SummaryCard(
                title: '尿尿',
                value: '${state.todaySummary.peeCount}',
                icon: Icons.water_drop,
                selected: state.filterType == EventType.pee,
                onTap: () => onSelectFilter(EventType.pee),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SummaryCard(
                title: '换尿布',
                value: '${state.todaySummary.diaperCount}',
                icon: Icons.checkroom,
                selected: state.filterType == EventType.diaper,
                onTap: () => onSelectFilter(EventType.diaper),
                compact: true,
              ),
              const SizedBox(width: 8),
              SummaryCard(
                title: '吸奶',
                value: '${state.todaySummary.pumpCount}',
                icon: Icons.science,
                selected: state.filterType == EventType.pump,
                onTap: () => onSelectFilter(EventType.pump),
                compact: true,
              ),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.nextReminderAt == null
                        ? '下次提醒：暂无（先记录一条喂奶）'
                        : '下次提醒：${DateFormat('MM-dd HH:mm').format(state.nextReminderAt!)}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onAddEvent(EventType.feed),
                  child: const Text('记录吃奶'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onAddEvent(EventType.poop),
                  child: const Text('记录便便'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onAddEvent(EventType.pee),
                  child: const Text('记录尿尿'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onAddEvent(EventType.diaper),
                  child: const Text('记录换尿布'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onAddEvent(EventType.pump),
                  child: const Text('记录吸奶'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _timelineTitle(state.filterType),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (state.timeline.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('暂无记录，先新增一条吧。'),
            )
          else
            ...state.timeline.map(
              (event) => _TimelineCard(event, onTap: () => onEditEvent(event)),
            ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard(this.event, {this.onTap});

  final BabyEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconFor(event.type)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.type.labelZh,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MM-dd HH:mm').format(event.occurredAt),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleFor(event),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  return '${filterType.labelZh}-时间线';
}
