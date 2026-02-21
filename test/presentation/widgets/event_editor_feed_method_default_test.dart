import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:baby_tracker/presentation/widgets/event_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new feed record defaults to bottled breast milk', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWalnieLightTheme(),
        home: Scaffold(
          body: EventEditorSheet(
            initialType: EventType.feed,
            onSubmit: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('瓶装母乳'), findsOneWidget);
  });
}
