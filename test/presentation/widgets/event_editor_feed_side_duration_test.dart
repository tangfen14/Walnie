import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:baby_tracker/presentation/widgets/event_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('right-only legacy breastfeeding restores right side value', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSheet(
        initialEvent: BabyEvent(
          type: EventType.feed,
          occurredAt: DateTime(2026, 2, 22, 14, 29),
          feedMethod: FeedMethod.breastRight,
          durationMin: 10,
        ),
      ),
    );

    final leftInput = tester.widget<TextField>(
      find.widgetWithText(TextField, '左侧时长(分钟)'),
    );
    final rightInput = tester.widget<TextField>(
      find.widgetWithText(TextField, '右侧时长(分钟)'),
    );

    expect(leftInput.controller?.text ?? '', isEmpty);
    expect(rightInput.controller?.text, '10');
  });

  testWidgets('saving right-only breastfeeding stores method as right side', (
    tester,
  ) async {
    BabyEvent? submitted;

    await tester.pumpWidget(
      buildSheet(
        initialType: EventType.feed,
        onSubmit: (event) async {
          submitted = event;
        },
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<FeedMethod>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('亲喂').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '右侧时长(分钟)'), '10');
    await tester.pump();

    await tester.tap(find.text('确认保存'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.feedMethod, FeedMethod.breastRight);
    expect(submitted!.durationMin, 10);
    expect(submitted!.eventMeta?.feedRightDurationMin, 10);
  });
}
