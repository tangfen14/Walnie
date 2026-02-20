import 'package:baby_tracker/domain/entities/baby_event.dart';
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.headerText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '识别内容：${widget.headerText}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('记录事件', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
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
              const SizedBox(height: 14),
              if (_eventType != EventType.pump)
                Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 8),
                    Text(DateFormat('MM-dd HH:mm').format(_occurredAt)),
                    const Spacer(),
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
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'MM-dd HH:mm',
                      ).format(_pumpStartAt ?? DateTime.now()),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickPumpStartAt,
                      child: const Text('吸奶开始'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.stop_circle_outlined),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'MM-dd HH:mm',
                      ).format(_pumpEndAt ?? DateTime.now()),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickPumpEndAt,
                      child: const Text('吸奶结束'),
                    ),
                  ],
                ),
              ],
              if (_eventType == EventType.feed) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<FeedMethod>(
                  key: ValueKey(_feedMethod),
                  initialValue: _feedMethod,
                  decoration: const InputDecoration(
                    labelText: '喂养方式',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '时长(分钟)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '毫升(ml)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_eventType == EventType.pump) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '奶量(ml)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '备注(可选)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('确认保存'),
                ),
              ),
              if (widget.initialEvent != null && widget.onDelete != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _submitting ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除记录'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
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
