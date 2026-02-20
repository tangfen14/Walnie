import 'dart:async';

import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:baby_tracker/presentation/widgets/voice_recording_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(speechChannel, null);
  });

  testWidgets(
    'does not throw setState-after-dispose when widget unmounts before speech init returns',
    (tester) async {
      final initializeCompleter = Completer<bool>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(speechChannel, (call) async {
            switch (call.method) {
              case 'initialize':
                return initializeCompleter.future;
              case 'listen':
                return true;
              case 'stop':
              case 'cancel':
                return null;
              case 'locales':
                return <dynamic>[];
              case 'has_permission':
                return true;
              default:
                return null;
            }
          });

      await tester.pumpWidget(
        MaterialApp(
          theme: buildWalnieLightTheme(),
          home: const Scaffold(body: VoiceRecordingSheet()),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      initializeCompleter.complete(true);
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
