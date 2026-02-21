import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:baby_tracker/presentation/widgets/event_editor_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  Widget buildSheet({
    EventType initialType = EventType.feed,
    BabyEvent? initialEvent,
    Future<void> Function(BabyEvent event)? onSubmit,
  }) {
    return MaterialApp(
      theme: buildWalnieLightTheme(),
      home: Scaffold(
        body: EventEditorSheet(
          initialType: initialType,
          initialEvent: initialEvent,
          onSubmit: onSubmit ?? (_) async {},
        ),
      ),
    );
  }

  testWidgets('does not show helper line or event type section', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());

    expect(find.text('按区块填写，减少漏填'), findsNothing);
    expect(find.text('事件类型'), findsNothing);
    expect(find.text('核心信息'), findsNothing);
    expect(find.text('备注'), findsNothing);
  });

  testWidgets('feed method defaults to bottled breast milk', (tester) async {
    await tester.pumpWidget(buildSheet(initialType: EventType.feed));
    expect(find.text('瓶装母乳'), findsOneWidget);
  });

  testWidgets('breastfeeding shows left and right duration only', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: DateTime(2026, 2, 21, 8, 42),
          feedMethod: FeedMethod.breastLeft,
        ),
      ),
    );

    expect(find.text('左侧时长(分钟)'), findsOneWidget);
    expect(find.text('右侧时长(分钟)'), findsOneWidget);
    expect(find.text('瓶装毫升(ml)'), findsNothing);
  });

  testWidgets('bottle feeding shows ml only', (tester) async {
    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: DateTime(2026, 2, 21, 8, 42),
          feedMethod: FeedMethod.bottleFormula,
        ),
      ),
    );

    expect(find.text('左侧时长(分钟)'), findsNothing);
    expect(find.text('右侧时长(分钟)'), findsNothing);
    expect(find.text('瓶装毫升(ml)'), findsOneWidget);
  });

  testWidgets('mixed feeding shows both side durations and bottle ml', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: DateTime(2026, 2, 21, 8, 42),
          feedMethod: FeedMethod.mixed,
        ),
      ),
    );

    expect(find.text('左侧时长(分钟)'), findsOneWidget);
    expect(find.text('右侧时长(分钟)'), findsOneWidget);
    expect(find.text('瓶装毫升(ml)'), findsOneWidget);
  });

  testWidgets('time edit opens single bottom-sheet date-time picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: DateTime(2026, 2, 21, 8, 42),
          feedMethod: FeedMethod.breastLeft,
        ),
      ),
    );

    await tester.tap(find.text('修改时间'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('eventDateTimePickerSheet')), findsOne);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });

  testWidgets('confirming picker updates displayed occurred time', (
    tester,
  ) async {
    final initial = DateTime(2026, 2, 21, 8, 42);
    final next = DateTime(2026, 2, 21, 9, 5);

    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: initial,
          feedMethod: FeedMethod.breastLeft,
        ),
      ),
    );

    await tester.tap(find.text('修改时间'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byKey(const ValueKey('eventDateTimePicker')),
    );
    picker.onDateTimeChanged(next);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('eventDateTimePickerConfirm')));
    await tester.pumpAndSettle();

    expect(find.text(DateFormat('MM-dd HH:mm').format(next)), findsOneWidget);
  });

  testWidgets('canceling picker keeps original occurred time', (tester) async {
    final initial = DateTime(2026, 2, 21, 8, 42);
    final next = DateTime(2026, 2, 21, 9, 5);

    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: initial,
          feedMethod: FeedMethod.breastLeft,
        ),
      ),
    );

    await tester.tap(find.text('修改时间'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byKey(const ValueKey('eventDateTimePicker')),
    );
    picker.onDateTimeChanged(next);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('eventDateTimePickerCancel')));
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat('MM-dd HH:mm').format(initial)),
      findsOneWidget,
    );
    expect(find.text(DateFormat('MM-dd HH:mm').format(next)), findsNothing);
  });

  testWidgets('changing pump start later auto-adjusts pump end', (
    tester,
  ) async {
    final start = DateTime(2026, 2, 21, 8, 0);
    final end = DateTime(2026, 2, 21, 8, 30);
    final nextStart = DateTime(2026, 2, 21, 9, 0);
    final expectedEnd = nextStart.add(const Duration(minutes: 20));

    await tester.pumpWidget(
      buildSheet(
        initialType: EventType.pump,
        initialEvent: BabyEvent(
          type: EventType.pump,
          occurredAt: start,
          pumpStartAt: start,
          pumpEndAt: end,
          amountMl: 80,
        ),
      ),
    );

    await tester.tap(find.text('吸奶开始'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byKey(const ValueKey('eventDateTimePicker')),
    );
    picker.onDateTimeChanged(nextStart);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('eventDateTimePickerConfirm')));
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat('MM-dd HH:mm').format(nextStart)),
      findsOneWidget,
    );
    expect(
      find.text(DateFormat('MM-dd HH:mm').format(expectedEnd)),
      findsOneWidget,
    );
  });

  testWidgets('changing pump end updates only end time', (tester) async {
    final start = DateTime(2026, 2, 21, 8, 0);
    final end = DateTime(2026, 2, 21, 8, 30);
    final nextEnd = DateTime(2026, 2, 21, 8, 50);

    await tester.pumpWidget(
      buildSheet(
        initialType: EventType.pump,
        initialEvent: BabyEvent(
          type: EventType.pump,
          occurredAt: start,
          pumpStartAt: start,
          pumpEndAt: end,
          amountMl: 80,
        ),
      ),
    );

    await tester.tap(find.text('吸奶结束'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byKey(const ValueKey('eventDateTimePicker')),
    );
    picker.onDateTimeChanged(nextEnd);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('eventDateTimePickerConfirm')));
    await tester.pumpAndSettle();

    expect(find.text(DateFormat('MM-dd HH:mm').format(start)), findsOneWidget);
    expect(
      find.text(DateFormat('MM-dd HH:mm').format(nextEnd)),
      findsOneWidget,
    );
  });

  testWidgets('pump splits left and right ml then auto-sums on save', (
    tester,
  ) async {
    final start = DateTime(2026, 2, 21, 8, 0);
    BabyEvent? submitted;

    await tester.pumpWidget(
      buildSheet(
        initialType: EventType.pump,
        initialEvent: BabyEvent(
          type: EventType.pump,
          occurredAt: start,
          pumpStartAt: start,
          pumpEndAt: start.add(const Duration(minutes: 20)),
          amountMl: 80,
        ),
        onSubmit: (event) async {
          submitted = event;
        },
      ),
    );

    expect(find.byKey(const ValueKey('pumpLeftMlInput')), findsOneWidget);
    expect(find.byKey(const ValueKey('pumpRightMlInput')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('pumpLeftMlInput')), '30');
    await tester.enterText(
      find.byKey(const ValueKey('pumpRightMlInput')),
      '20',
    );
    await tester.pump();

    expect(find.text('总奶量：50 ml'), findsOneWidget);

    await tester.tap(find.text('确认保存'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.amountMl, 50);
    expect(submitted!.eventMeta?.pumpLeftMl, 30);
    expect(submitted!.eventMeta?.pumpRightMl, 20);
  });
}
