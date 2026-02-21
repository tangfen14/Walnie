import 'package:baby_tracker/app/providers.dart';
import 'package:baby_tracker/application/usecases/parse_voice_command_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/today_summary.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/presentation/controllers/home_controller.dart';
import 'package:baby_tracker/presentation/controllers/home_state.dart';
import 'package:baby_tracker/presentation/pages/home_page.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHomeController extends HomeController {
  static HomeState seed = _buildSeedState();

  static HomeState _buildSeedState() {
    final now = DateTime.now();
    final timeline = [
      BabyEvent(
        id: 'feed-1',
        type: EventType.feed,
        occurredAt: now.subtract(const Duration(minutes: 10)),
        feedMethod: FeedMethod.bottleBreastmilk,
        amountMl: 60,
      ),
      BabyEvent(
        id: 'pee-1',
        type: EventType.pee,
        occurredAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
    return HomeState(
      allTimeline: timeline,
      timeline: timeline,
      todaySummary: const TodaySummary(
        feedCount: 1,
        poopCount: 0,
        peeCount: 1,
        diaperCount: 0,
        pumpCount: 0,
      ),
      intervalHours: 3,
      nextReminderAt: now.add(const Duration(hours: 2)),
      filterType: null,
      isTimelineRefreshing: false,
      uiNotice: null,
      uiNoticeVersion: 0,
    );
  }

  @override
  Future<HomeState> build() async {
    return seed;
  }

  @override
  void setFilter(EventType? type) {
    filterType = type;
    final current = state.value!;
    final nextTimeline = type == null
        ? current.allTimeline
        : current.allTimeline
              .where((item) => item.type == type)
              .toList(growable: false);
    state = AsyncData(
      current.copyWith(filterType: type, timeline: nextTimeline),
    );
  }

  @override
  Future<void> refreshData({String? refreshFailureNotice}) async {
    final current = state.value!;
    state = AsyncData(current.copyWith(isTimelineRefreshing: true));
  }

  @override
  Future<void> addEvent(BabyEvent event) async {}

  @override
  Future<void> deleteEvent(BabyEvent event) async {}

  @override
  Future<void> updateReminderInterval(int intervalHours) async {}

  @override
  Future<String> answerQuery(VoiceIntent intent) async => 'ok';

  void setTimelineRefreshing(bool value) {
    final current = state.value!;
    state = AsyncData(current.copyWith(isTimelineRefreshing: value));
  }

  void emitNotice(String notice, {bool bumpVersion = true}) {
    final current = state.value!;
    state = AsyncData(
      current.copyWith(
        uiNotice: notice,
        uiNoticeVersion: bumpVersion
            ? current.uiNoticeVersion + 1
            : current.uiNoticeVersion,
      ),
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
  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    HomeState? seed,
  }) async {
    _FakeHomeController.seed = seed ?? _FakeHomeController._buildSeedState();
    final container = ProviderContainer(
      overrides: [
        homeControllerProvider.overrideWith(_FakeHomeController.new),
        parseVoiceCommandUseCaseProvider.overrideWithValue(
          ParseVoiceCommandUseCase(_FakeVoiceCommandService()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(homeControllerProvider.future);

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

  testWidgets('filter tap does not show full-screen loading', (tester) async {
    await pumpHome(tester);

    expect(find.text('今日概览与快速记录'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overview-filter-feed')));
    await tester.pump();

    expect(find.text('今日概览与快速记录'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-full-loading')), findsNothing);
  });

  testWidgets('feed labels use 喂奶 consistently', (tester) async {
    await pumpHome(tester);

    expect(find.text('喂奶'), findsWidgets);
    expect(find.text('吃奶'), findsNothing);
  });

  testWidgets('brand header shows baby age day badge', (tester) async {
    await pumpHome(tester);

    final badge = find.byKey(const ValueKey('baby-age-badge'));
    expect(badge, findsOneWidget);

    final badgeText = find.descendant(of: badge, matching: find.byType(Text));
    expect(badgeText, findsOneWidget);
    final textWidget = tester.widget<Text>(badgeText);
    expect(textWidget.data, matches(RegExp(r'^第\d+天$')));
  });

  testWidgets('timeline skeleton appears while refreshing', (tester) async {
    final container = await pumpHome(tester);
    final notifier =
        container.read(homeControllerProvider.notifier) as _FakeHomeController;

    notifier.setTimelineRefreshing(true);
    expect(
      container.read(homeControllerProvider).value!.isTimelineRefreshing,
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(
      container.read(homeControllerProvider).value!.isTimelineRefreshing,
      isTrue,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('timeline-skeleton')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-full-loading')), findsNothing);
  });

  testWidgets('ui notice shown only when version changes', (tester) async {
    final container = await pumpHome(tester);
    final notifier =
        container.read(homeControllerProvider.notifier) as _FakeHomeController;
    const message = '刷新失败，请稍后重试';

    notifier.emitNotice(message);
    await tester.pump();
    expect(find.text(message), findsOneWidget);

    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    );
    messenger.hideCurrentSnackBar();
    await tester.pumpAndSettle();

    notifier.emitNotice(message, bumpVersion: false);
    await tester.pump();
    expect(find.text(message), findsNothing);

    notifier.emitNotice(message);
    await tester.pump();
    expect(find.text(message), findsOneWidget);
  });
}
