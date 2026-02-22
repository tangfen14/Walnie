import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/parse_voice_command_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/presentation/controllers/home_controller.dart';
import 'package:baby_tracker/presentation/controllers/home_state.dart';
import 'package:baby_tracker/presentation/pages/home_page.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingNetworkHomeController extends HomeController {
  int refreshDataCalls = 0;

  static Exception _error() => Exception(
    'ClientException with SocketException: Connection failed '
    '(OS Error: No route to host, errno = 65)',
  );

  @override
  Future<HomeState> build() async {
    throw _error();
  }

  @override
  Future<void> refreshData({
    String? refreshFailureNotice,
    bool showFailureNotice = true,
    bool showTimelineRefreshing = true,
  }) async {
    refreshDataCalls += 1;
    state = const AsyncLoading();
    state = AsyncError(_error(), StackTrace.current);
  }

  @override
  Future<void> addEvent(BabyEvent event) async {}

  @override
  Future<void> deleteEvent(BabyEvent event) async {}

  @override
  Future<void> updateReminderInterval(int intervalHours) async {}

  @override
  Future<String> answerQuery(VoiceIntent intent) async => '';
}

class _SlowFailingNetworkHomeController extends _FailingNetworkHomeController {
  @override
  Future<void> refreshData({
    String? refreshFailureNotice,
    bool showFailureNotice = true,
    bool showTimelineRefreshing = true,
  }) async {
    refreshDataCalls += 1;
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = AsyncError(
      _FailingNetworkHomeController._error(),
      StackTrace.current,
    );
  }
}

class _FakeVoiceCommandService implements VoiceCommandService {
  @override
  Future<VoiceIntent> parse(
    String transcript, {
    VoiceParseProgressListener? onProgress,
    VoiceParseCancellationToken? cancellationToken,
  }) async {
    return VoiceIntent.unknown(transcript: transcript);
  }

  @override
  Future<String> transcribe() async => '';
}

void main() {
  Future<ProviderContainer> pumpFailureHome(
    WidgetTester tester, {
    HomeController Function() controller = _FailingNetworkHomeController.new,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        homeControllerProvider.overrideWith(controller),
        parseVoiceCommandUseCaseProvider.overrideWithValue(
          ParseVoiceCommandUseCase(_FakeVoiceCommandService()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildWalnieLightTheme(),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('network failure shows settings guidance', (tester) async {
    await pumpFailureHome(tester);

    expect(
      find.byKey(const ValueKey('home-initial-network-auto-retry-hint')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-initial-network-settings-hint')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('open-system-settings-button')),
      findsOneWidget,
    );
  });

  testWidgets('network failure triggers auto retry', (tester) async {
    final container = await pumpFailureHome(tester);
    final notifier =
        container.read(homeControllerProvider.notifier)
            as _FailingNetworkHomeController;

    expect(notifier.refreshDataCalls, 0);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(notifier.refreshDataCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('network auto retry stops after max attempts', (tester) async {
    final container = await pumpFailureHome(
      tester,
      controller: _SlowFailingNetworkHomeController.new,
    );
    final notifier =
        container.read(homeControllerProvider.notifier)
            as _SlowFailingNetworkHomeController;

    for (var i = 0; i < 120; i += 1) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(notifier.refreshDataCalls, 5);
    expect(find.textContaining('自动重试已结束'), findsOneWidget);
  });
}
