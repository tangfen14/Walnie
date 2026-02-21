import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme_extensions.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:baby_tracker/presentation/widgets/event_note_editor_sheet.dart';
import 'package:flutter/cupertino.dart';
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
  late final TextEditingController _leftDurationController;
  late final TextEditingController _rightDurationController;
  late final TextEditingController _pumpLeftAmountController;
  late final TextEditingController _pumpRightAmountController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DiaperStatus _diaperStatus;
  late bool _changedDiaper;
  late bool _hasRash;
  late List<EventAttachment> _attachments;

  bool _submitting = false;

  bool get _isDiaperLike {
    return _eventType == EventType.diaper ||
        _eventType == EventType.poop ||
        _eventType == EventType.pee;
  }

  @override
  void initState() {
    super.initState();

    final initial = widget.initialEvent;
    _eventType = initial?.type ?? widget.initialType;
    _occurredAt = initial?.occurredAt ?? DateTime.now();
    final initialMethod = _normalizeFeedMethodForEditor(initial?.feedMethod);
    _feedMethod = _eventType == EventType.feed
        ? (initialMethod ?? FeedMethod.bottleBreastmilk)
        : null;

    if (_eventType == EventType.pump) {
      _pumpStartAt =
          initial?.pumpStartAt ?? initial?.occurredAt ?? DateTime.now();
      _pumpEndAt =
          initial?.pumpEndAt ?? _pumpStartAt!.add(const Duration(minutes: 20));
    }

    final initialEventMeta = initial?.eventMeta;
    final initialIsBreastBased =
        initialMethod == FeedMethod.breastLeft ||
        initialMethod == FeedMethod.breastRight ||
        initialMethod == FeedMethod.mixed;
    final initialLeftDuration =
        initialEventMeta?.feedLeftDurationMin ??
        (initialIsBreastBased && initialMethod != FeedMethod.breastRight
            ? initial?.durationMin
            : null);
    final initialRightDuration =
        initialEventMeta?.feedRightDurationMin ??
        (initialIsBreastBased && initialMethod == FeedMethod.breastRight
            ? initial?.durationMin
            : null);
    final initialPumpLeftMl = initialEventMeta?.pumpLeftMl ?? initial?.amountMl;
    final initialPumpRightMl = initialEventMeta?.pumpRightMl;
    _leftDurationController = TextEditingController(
      text: initialLeftDuration?.toString() ?? '',
    );
    _rightDurationController = TextEditingController(
      text: initialRightDuration?.toString() ?? '',
    );
    _pumpLeftAmountController = TextEditingController(
      text: _eventType == EventType.pump
          ? initialPumpLeftMl?.toString() ?? ''
          : '',
    );
    _pumpRightAmountController = TextEditingController(
      text: _eventType == EventType.pump
          ? initialPumpRightMl?.toString() ?? ''
          : '',
    );
    _amountController = TextEditingController(
      text: _eventType == EventType.feed
          ? initial?.amountMl?.toString() ?? ''
          : '',
    );
    _noteController = TextEditingController(text: initial?.note ?? '');

    final eventMeta = initial?.eventMeta;
    _diaperStatus = eventMeta?.status ?? DiaperStatus.mixed;
    _changedDiaper = eventMeta?.changedDiaper ?? true;
    _hasRash = eventMeta?.hasRash ?? false;
    _attachments = List<EventAttachment>.from(
      eventMeta?.attachments ?? const [],
    );
  }

  @override
  void dispose() {
    _leftDurationController.dispose();
    _rightDurationController.dispose();
    _pumpLeftAmountController.dispose();
    _pumpRightAmountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  FeedMethod? _normalizeFeedMethodForEditor(FeedMethod? method) {
    if (method == FeedMethod.breastRight) {
      return FeedMethod.breastLeft;
    }
    return method;
  }

  bool get _showFeedSideDurations {
    if (_eventType != EventType.feed) {
      return false;
    }

    return _feedMethod == FeedMethod.breastLeft ||
        _feedMethod == FeedMethod.breastRight ||
        _feedMethod == FeedMethod.mixed;
  }

  bool get _showFeedBottleAmount {
    if (_eventType != EventType.feed) {
      return false;
    }

    return _feedMethod == FeedMethod.bottleFormula ||
        _feedMethod == FeedMethod.bottleBreastmilk ||
        _feedMethod == FeedMethod.mixed;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDiaperLike) {
      return _buildDiaperLikeEditor(context);
    }
    return _buildDefaultEditor(context);
  }

  Widget _buildDefaultEditor(BuildContext context) {
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
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
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
                    if (_eventType == EventType.feed) ...[
                      DropdownButtonFormField<FeedMethod>(
                        key: ValueKey(_feedMethod),
                        initialValue: _feedMethod,
                        decoration: const InputDecoration(labelText: '喂养方式'),
                        items:
                            [
                                  FeedMethod.bottleBreastmilk,
                                  FeedMethod.breastLeft,
                                  FeedMethod.bottleFormula,
                                  FeedMethod.mixed,
                                ]
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
                            if (!_showFeedSideDurations) {
                              _leftDurationController.clear();
                              _rightDurationController.clear();
                            }
                            if (!_showFeedBottleAmount) {
                              _amountController.clear();
                            }
                          });
                        },
                      ),
                      if (_showFeedSideDurations) ...[
                        const SizedBox(height: WalnieTokens.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _leftDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '左侧时长(分钟)',
                                ),
                              ),
                            ),
                            const SizedBox(width: WalnieTokens.spacingSm),
                            Expanded(
                              child: TextField(
                                controller: _rightDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '右侧时长(分钟)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_showFeedBottleAmount) ...[
                        const SizedBox(height: WalnieTokens.spacingSm),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '瓶装毫升(ml)',
                          ),
                        ),
                      ],
                    ] else if (_eventType == EventType.pump) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('pumpLeftMlInput'),
                              controller: _pumpLeftAmountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                labelText: '左奶量(ml)',
                              ),
                            ),
                          ),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: TextField(
                              key: const ValueKey('pumpRightMlInput'),
                              controller: _pumpRightAmountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) {
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                labelText: '右奶量(ml)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Text(
                        '总奶量：${_pumpTotalAmountMl ?? 0} ml',
                        key: const ValueKey('pumpTotalAmountText'),
                        style: textTheme.titleMedium,
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

  Widget _buildDiaperLikeEditor(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final timelineColors = theme.timelineColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: WalnieTokens.spacingMd,
          right: WalnieTokens.spacingMd,
          top: WalnieTokens.spacingSm,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + WalnieTokens.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    Text('换尿布', style: textTheme.titleLarge),
                  ],
                ),
              ),
              if (widget.headerText != null) ...[
                const SizedBox(height: WalnieTokens.spacingSm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(WalnieTokens.spacingMd),
                    child: Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color: colorScheme.primary,
                        ),
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
                ),
              ],
              const SizedBox(height: WalnieTokens.spacingSm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(WalnieTokens.spacingMd),
                  child: Column(
                    children: [
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Icon(
                        Icons.checkroom,
                        size: 68,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: WalnieTokens.spacingLg),
                      _labelRow(
                        context,
                        label: '更换时间',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('M月d日 HH:mm').format(_occurredAt),
                              style: textTheme.bodyLarge,
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        onTap: _pickOccurredAt,
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('尿布状态', style: textTheme.titleMedium),
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Row(
                        children: [
                          Expanded(
                            child: _StatusOption(
                              label: DiaperStatus.poop.labelZh,
                              selected: _diaperStatus == DiaperStatus.poop,
                              icon: Icons.circle,
                              iconColor: timelineColors.poop,
                              onTap: () {
                                setState(() {
                                  _diaperStatus = DiaperStatus.poop;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: _StatusOption(
                              label: DiaperStatus.pee.labelZh,
                              selected: _diaperStatus == DiaperStatus.pee,
                              icon: Icons.water_drop,
                              iconColor: timelineColors.pee,
                              onTap: () {
                                setState(() {
                                  _diaperStatus = DiaperStatus.pee;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: _StatusOption(
                              label: DiaperStatus.mixed.labelZh,
                              selected: _diaperStatus == DiaperStatus.mixed,
                              icon: Icons.change_circle,
                              iconColor: colorScheme.primary,
                              onTap: () {
                                setState(() {
                                  _diaperStatus = DiaperStatus.mixed;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Row(
                        children: [
                          Expanded(
                            child: Text('更换纸布', style: textTheme.titleMedium),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('是'),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('否'),
                              ),
                            ],
                            selected: {_changedDiaper},
                            onSelectionChanged: (set) {
                              setState(() {
                                _changedDiaper = set.first;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: WalnieTokens.spacingSm),
                      Row(
                        children: [
                          Expanded(
                            child: Text('红屁屁', style: textTheme.titleMedium),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('是'),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('否'),
                              ),
                            ],
                            selected: {_hasRash},
                            onSelectionChanged: (set) {
                              setState(() {
                                _hasRash = set.first;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 120),
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _openNoteEditor,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(_noteButtonText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: WalnieTokens.spacingLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ),
              if (widget.initialEvent != null && widget.onDelete != null) ...[
                const SizedBox(height: WalnieTokens.spacingSm),
                TextButton.icon(
                  onPressed: _submitting ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除记录'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelRow(
    BuildContext context, {
    required String label,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WalnieTokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  int? _sumFeedSideDuration(int? leftDurationMin, int? rightDurationMin) {
    final left = leftDurationMin ?? 0;
    final right = rightDurationMin ?? 0;
    if (left <= 0 && right <= 0) {
      return null;
    }
    return left + right;
  }

  int? _sumPumpSideAmount(int? leftAmountMl, int? rightAmountMl) {
    final left = leftAmountMl ?? 0;
    final right = rightAmountMl ?? 0;
    if (left <= 0 && right <= 0) {
      return null;
    }
    return left + right;
  }

  EventMeta? _buildFeedEventMeta({
    required int? leftDurationMin,
    required int? rightDurationMin,
  }) {
    if (leftDurationMin == null && rightDurationMin == null) {
      return null;
    }

    return EventMeta(
      schemaVersion: 1,
      feedLeftDurationMin: leftDurationMin,
      feedRightDurationMin: rightDurationMin,
      attachments: const [],
    );
  }

  EventMeta? _buildPumpEventMeta({
    required int? leftAmountMl,
    required int? rightAmountMl,
  }) {
    if (leftAmountMl == null && rightAmountMl == null) {
      return null;
    }

    return EventMeta(
      schemaVersion: 1,
      pumpLeftMl: leftAmountMl,
      pumpRightMl: rightAmountMl,
      attachments: const [],
    );
  }

  int? get _pumpTotalAmountMl {
    final left = int.tryParse(_pumpLeftAmountController.text.trim());
    final right = int.tryParse(_pumpRightAmountController.text.trim());
    return _sumPumpSideAmount(left, right);
  }

  String get _noteButtonText {
    final note = _noteController.text.trim();
    final imageCount = _attachments.length;
    if (note.isEmpty && imageCount == 0) {
      return '备注';
    }

    final parts = <String>[];
    if (imageCount > 0) {
      parts.add('$imageCount 张图片');
    }
    if (note.isNotEmpty) {
      parts.add('有文字备注');
    }
    return parts.join(' · ');
  }

  Future<void> _openNoteEditor() async {
    final draft = await showEventNoteEditorSheet(
      context,
      initialNote: _noteController.text,
      initialAttachments: _attachments,
      maxAttachments: 3,
    );

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _noteController.text = draft.note;
      _attachments = List<EventAttachment>.from(draft.attachments);
    });
  }

  Future<void> _pickOccurredAt() async {
    final picked = await _pickDateTime(_occurredAt, title: '修改时间');
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _occurredAt = picked;
    });
  }

  Future<void> _pickPumpStartAt() async {
    final initialValue = _pumpStartAt ?? DateTime.now();
    final picked = await _pickDateTime(initialValue, title: '吸奶开始');
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
    final picked = await _pickDateTime(initialValue, title: '吸奶结束');
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _pumpEndAt = picked;
    });
  }

  Future<DateTime?> _pickDateTime(
    DateTime initialValue, {
    String? title,
  }) async {
    final minDate = DateTime.now().subtract(const Duration(days: 30));
    final maxDate = DateTime.now().add(const Duration(days: 1));
    final clampedInitial = _clampDateTime(
      DateTime(
        initialValue.year,
        initialValue.month,
        initialValue.day,
        initialValue.hour,
        initialValue.minute,
      ),
      minDate,
      maxDate,
    );

    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) {
        var selected = clampedInitial;
        return _DateTimePickerSheet(
          title: title ?? '选择时间',
          initialValue: clampedInitial,
          minDate: minDate,
          maxDate: maxDate,
          onChanged: (value) {
            selected = value;
          },
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            final normalized = DateTime(
              selected.year,
              selected.month,
              selected.day,
              selected.hour,
              selected.minute,
            );
            Navigator.of(context).pop(normalized);
          },
        );
      },
    );
  }

  DateTime _clampDateTime(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) {
      return min;
    }
    if (value.isAfter(max)) {
      return max;
    }
    return value;
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
    });

    try {
      final isFeed = _eventType == EventType.feed;
      final isPump = _eventType == EventType.pump;
      final isDiaperLike = _isDiaperLike;
      final targetType = isDiaperLike ? EventType.diaper : _eventType;
      final trimmedNote = _noteController.text.trim();
      final leftDurationMin = int.tryParse(_leftDurationController.text.trim());
      final rightDurationMin = int.tryParse(
        _rightDurationController.text.trim(),
      );
      final amountMl = int.tryParse(_amountController.text.trim());
      final pumpLeftAmountMl = int.tryParse(
        _pumpLeftAmountController.text.trim(),
      );
      final pumpRightAmountMl = int.tryParse(
        _pumpRightAmountController.text.trim(),
      );
      final hasFeedSideDurations = isFeed && _showFeedSideDurations;
      final hasFeedBottleAmount = isFeed && _showFeedBottleAmount;
      final durationMin = hasFeedSideDurations
          ? _sumFeedSideDuration(leftDurationMin, rightDurationMin)
          : null;
      final resolvedAmountMl = isPump
          ? _sumPumpSideAmount(pumpLeftAmountMl, pumpRightAmountMl)
          : (hasFeedBottleAmount ? amountMl : null);
      final feedEventMeta = isFeed
          ? _buildFeedEventMeta(
              leftDurationMin: hasFeedSideDurations ? leftDurationMin : null,
              rightDurationMin: hasFeedSideDurations ? rightDurationMin : null,
            )
          : null;
      final pumpEventMeta = isPump
          ? _buildPumpEventMeta(
              leftAmountMl: pumpLeftAmountMl,
              rightAmountMl: pumpRightAmountMl,
            )
          : null;
      final clearDuration =
          !isFeed || !hasFeedSideDurations || durationMin == null;
      final clearAmount =
          (!isFeed && !isPump) ||
          (isFeed && !hasFeedBottleAmount) ||
          (isFeed && amountMl == null) ||
          (isPump && resolvedAmountMl == null);
      final occurredAt = isPump ? (_pumpStartAt ?? _occurredAt) : _occurredAt;

      final eventMeta = isDiaperLike
          ? EventMeta(
              schemaVersion: 1,
              status: _diaperStatus,
              changedDiaper: _changedDiaper,
              hasRash: _hasRash,
              attachments: List<EventAttachment>.from(_attachments),
            )
          : (isFeed ? feedEventMeta : (isPump ? pumpEventMeta : null));

      final event = widget.initialEvent != null
          ? widget.initialEvent!.copyWith(
              type: targetType,
              occurredAt: occurredAt,
              feedMethod: isFeed ? _feedMethod : null,
              durationMin: isFeed ? durationMin : null,
              amountMl: (isFeed || isPump) ? resolvedAmountMl : null,
              pumpStartAt: isPump ? _pumpStartAt : null,
              pumpEndAt: isPump ? _pumpEndAt : null,
              note: trimmedNote.isEmpty ? null : trimmedNote,
              eventMeta: eventMeta,
              clearFeedMethod: !isFeed,
              clearDuration: clearDuration,
              clearAmount: clearAmount,
              clearPumpStartAt: !isPump,
              clearPumpEndAt: !isPump,
              clearNote: trimmedNote.isEmpty,
              clearEventMeta:
                  !isDiaperLike &&
                  ((isFeed && feedEventMeta == null) ||
                      (isPump && pumpEventMeta == null) ||
                      (!isFeed && !isPump)),
            )
          : BabyEvent(
              type: targetType,
              occurredAt: occurredAt,
              feedMethod: isFeed ? _feedMethod : null,
              durationMin: isFeed ? durationMin : null,
              amountMl: (isFeed || isPump) ? resolvedAmountMl : null,
              pumpStartAt: isPump ? _pumpStartAt : null,
              pumpEndAt: isPump ? _pumpEndAt : null,
              note: trimmedNote.isEmpty ? null : trimmedNote,
              eventMeta: eventMeta,
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

class _DateTimePickerSheet extends StatelessWidget {
  const _DateTimePickerSheet({
    required this.title,
    required this.initialValue,
    required this.minDate,
    required this.maxDate,
    required this.onChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final DateTime initialValue;
  final DateTime minDate;
  final DateTime maxDate;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('eventDateTimePickerSheet'),
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        WalnieTokens.spacingSm,
        WalnieTokens.spacingSm,
        WalnieTokens.spacingSm,
        WalnieTokens.spacingMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TextButton(
                key: const ValueKey('eventDateTimePickerCancel'),
                onPressed: onCancel,
                child: const Text('取消'),
              ),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                key: const ValueKey('eventDateTimePickerConfirm'),
                onPressed: onConfirm,
                child: const Text('确认'),
              ),
            ],
          ),
          const SizedBox(height: WalnieTokens.spacingXs),
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              key: const ValueKey('eventDateTimePicker'),
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: initialValue,
              minimumDate: minDate,
              maximumDate: maxDate,
              use24hFormat: true,
              minuteInterval: 1,
              onDateTimeChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: WalnieTokens.spacingSm,
            horizontal: WalnieTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
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
