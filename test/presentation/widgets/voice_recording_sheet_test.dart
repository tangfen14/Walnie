import 'dart:async';

import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:baby_tracker/presentation/widgets/voice_recording_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');

  void mockSpeechChannel({FutureOr<bool> Function()? onInitialize}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(speechChannel, (call) async {
          switch (call.method) {
            case 'initialize':
              if (onInitialize != null) {
                return onInitialize();
              }
              return false;
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
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(speechChannel, null);
  });

  testWidgets('shows voice command example hints', (tester) async {
    mockSpeechChannel();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildWalnieLightTheme(),
        home: const Scaffold(body: VoiceRecordingSheet()),
      ),
    );

    await tester.pump();

    expect(find.text('您可以说：「17点10分炫了60ml」、「8点20换了纸尿裤」'), findsOneWidget);
    expect(find.text('录音'), findsNothing);
    expect(find.text('内容由 AI 生成'), findsNothing);
    expect(find.byKey(const Key('voicePulseRingInner')), findsOneWidget);
    expect(find.byKey(const Key('voicePulseRingOuter')), findsOneWidget);
    expect(find.byKey(const Key('voiceTranscriptSlot')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'does not throw setState-after-dispose when widget unmounts before speech init returns',
    (tester) async {
      final initializeCompleter = Completer<bool>();
      mockSpeechChannel(onInitialize: () => initializeCompleter.future);

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
