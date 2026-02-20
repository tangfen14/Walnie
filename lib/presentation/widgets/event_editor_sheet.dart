import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventEditorSheet extends StatefulWidget {
  const EventEditorSheet({
    super.key,
    required this.initialType,
    this.initialEvent,
    this.headerText,
    required this.onSubmit,
    this.onDelete,
  });

  final EventType initialType;
  final BabyEvent? initialEvent;
  final String? headerText;
  final Future<void> Function(BabyEvent event) onSubmit;
  final Future<void> Function(BabyEvent event)? onDelete;

  @override
  State<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<EventEditorSheet> {
  late EventType _eventType;
  late DateTime _occurredAt;
  FeedMethod? _feedMethod;
  DateTime? _pumpStartAt;
  DateTime? _pumpEndAt;
  late final TextEditingController _durationController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialEvent;
    _eventType = initial?.type ?? widget.initialType;
    _occurredAt = initial?.occurredAt ?? DateTime.now();
    _feedMethod = _eventType == EventType.feed
        ? (initial?.feedMethod ?? FeedMethod.bottleBreastmilk)
        : null;
    if (_eventType == EventType.pump) {
      _pumpStartAt =
          initial?.pumpStartAt ?? initial?.occurredAt ?? DateTime.now();
      _pumpEndAt =
          initial?.pumpEndAt ?? _pumpStartAt!.add(const Duration(minutes: 20));
    }

    _durationController = TextEditingController(
      text: initial?.durationMin?.toString() ?? '',
    );
    _amountController = TextEditingController(
      text: initial?.amountMl?.toString() ?? '',
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _durationController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: WalnieTokens.spacingLg,
          right: WalnieTokens.spacingLg,
          top: WalnieTokens.spacingXs,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + WalnieTokens.spacingXl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initialEvent == null ? '新建记录' : '编辑记录',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: '关闭编辑页面',
                    child: IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WalnieTokens.spacingXs),
              if (widget.headerText != null) ...[
                _SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.record_voice_over, color: colorScheme.primary),
                      const SizedBox(width: WalnieTokens.spacingSm),
                      Expanded(
                        child: Text(
                          '识别内容：${widget.headerText}',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WalnieTokens.spacingSm),
              ],
              Text('按区块填写，减少漏填', style: textTheme.bodyMedium),
              const SizedBox(height: WalnieTokens.spacingMd),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('事件类型', style: textTheme.titleMedium),
                    const SizedBox(height: WalnieTokens.spacingSm),
                    SegmentedButton<EventType>(
                      showSelectedIcon: false,
                      segments: EventType.values
                          .map(
                            (type) => ButtonSegment<EventType>(
                              value: type,
                              label: Text(type.labelZh),
                            ),
                          )
                          .toList(growable: false),
                      selected: {_eventType},
                      onSelectionChanged: (set) {
                        setState(() {
                          _eventType = set.first;
                          if (_eventType == EventType.feed) {
                            _feedMethod ??= FeedMethod.bottleBreastmilk;
                            _pumpStartAt = null;
                            _pumpEndAt = null;
                          } else if (_eventType == EventType.pump) {
                            _feedMethod = null;
                            _durationController.clear();
                            _pumpStartAt ??= DateTime.now();
                            _pumpEndAt ??= _pumpStartAt!.add(
                              const Duration(minutes: 20),
                            );
                          } else {
                            _feedMethod = null;
                            _durationController.clear();
                            _amountController.clear();
                            _pumpStartAt = null;
                            _pumpEndAt = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WalnieTokens.spacingSm),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('时间', style: textTheme.titleMedium),
                    const SizedBox(height: WalnieTokens.spacingSm),
                    if (_eventType != EventType.pump)
                      Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: Text(
                              DateFormat('MM-dd HH:mm').format(_occurredAt),
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickOccurredAt,
                            child: const Text('修改时间'),
                          ),
                        ],
                      ),
                    if (_eventType == EventType.pump) ...[
                      Row(
                        children: [
                          const Icon(Icons.play_circle_outline),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'MM-dd HH:mm',
                              ).format(_pumpStartAt ?? DateTime.now()),
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickPumpStartAt,
                            child: const Text('吸奶开始'),
                          ),
                        ],
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Row(
                        children: [
                          const Icon(Icons.stop_circle_outlined),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: Text(
                              DateFormat(
                                'MM-dd HH:mm',
                              ).format(_pumpEndAt ?? DateTime.now()),
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickPumpEndAt,
                            child: const Text('吸奶结束'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: WalnieTokens.spacingSm),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('核心信息', style: textTheme.titleMedium),
                    const SizedBox(height: WalnieTokens.spacingSm),
                    if (_eventType == EventType.feed) ...[
                      DropdownButtonFormField<FeedMethod>(
                        key: ValueKey(_feedMethod),
                        initialValue: _feedMethod,
                        decoration: const InputDecoration(labelText: '喂养方式'),
                        items: FeedMethod.values
                            .map(
                              (item) => DropdownMenuItem<FeedMethod>(
                                value: item,
                                child: Text(item.labelZh),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _feedMethod = value;
                          });
                        },
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '时长(分钟)',
                              ),
                            ),
                          ),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '毫升(ml)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_eventType == EventType.pump) ...[
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '奶量(ml)'),
                      ),
                    ] else
                      Text('当前事件无需额外字段', style: textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: WalnieTokens.spacingSm),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('备注', style: textTheme.titleMedium),
                    const SizedBox(height: WalnieTokens.spacingSm),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '备注(可选)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WalnieTokens.spacingMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_submitting ? '保存中...' : '确认保存'),
                ),
              ),
              if (widget.initialEvent != null && widget.onDelete != null) ...[
                const SizedBox(height: WalnieTokens.spacingSm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(WalnieTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: _submitting ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除记录'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickOccurredAt() async {
    final picked = await _pickDateTime(_occurredAt);
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _occurredAt = picked;
    });
  }

  Future<void> _pickPumpStartAt() async {
    final initialValue = _pumpStartAt ?? DateTime.now();
    final picked = await _pickDateTime(initialValue);
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _pumpStartAt = picked;
      if (_pumpEndAt == null || !_pumpEndAt!.isAfter(picked)) {
        _pumpEndAt = picked.add(const Duration(minutes: 20));
      }
    });
  }

  Future<void> _pickPumpEndAt() async {
    final fallbackStart = _pumpStartAt ?? DateTime.now();
    final initialValue =
        _pumpEndAt ?? fallbackStart.add(const Duration(minutes: 20));
    final picked = await _pickDateTime(initialValue);
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _pumpEndAt = picked;
    });
  }

  Future<DateTime?> _pickDateTime(DateTime initialValue) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: initialValue,
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
    });

    try {
      final isFeed = _eventType == EventType.feed;
      final isPump = _eventType == EventType.pump;
      final trimmedNote = _noteController.text.trim();
      final durationText = _durationController.text.trim();
      final clearFeedDuration = isFeed && durationText.isEmpty;
      final amountMl = int.tryParse(_amountController.text.trim());
      final durationMin = int.tryParse(durationText);
      final occurredAt = isPump ? (_pumpStartAt ?? _occurredAt) : _occurredAt;

      final event = widget.initialEvent != null
          ? widget.initialEvent!.copyWith(
              type: _eventType,
              occurredAt: occurredAt,
              feedMethod: isFeed ? _feedMethod : null,
              durationMin: isFeed ? durationMin : null,
              amountMl: (isFeed || isPump) ? amountMl : null,
              pumpStartAt: isPump ? _pumpStartAt : null,
              pumpEndAt: isPump ? _pumpEndAt : null,
              note: trimmedNote.isEmpty ? null : trimmedNote,
              clearFeedMethod: !isFeed,
              clearDuration: !isFeed || clearFeedDuration,
              clearAmount: !(isFeed || isPump),
              clearPumpStartAt: !isPump,
              clearPumpEndAt: !isPump,
              clearNote: trimmedNote.isEmpty,
            )
          : BabyEvent(
              type: _eventType,
              occurredAt: occurredAt,
              feedMethod: isFeed ? _feedMethod : null,
              durationMin: isFeed ? durationMin : null,
              amountMl: (isFeed || isPump) ? amountMl : null,
              pumpStartAt: isPump ? _pumpStartAt : null,
              pumpEndAt: isPump ? _pumpEndAt : null,
              note: trimmedNote.isEmpty ? null : trimmedNote,
            );

      await widget.onSubmit(event);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final event = widget.initialEvent;
    final onDelete = widget.onDelete;
    if (event == null || onDelete == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('删除后无法恢复，确定要删除这条记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await onDelete(event);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(WalnieTokens.spacingMd),
        child: child,
      ),
    );
  }
}
