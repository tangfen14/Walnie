import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/presentation/utils/timeline_day_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats feed group summary with total amount ml', () {
    final events = [
      BabyEvent(
        type: EventType.feed,
        occurredAt: DateTime(2026, 2, 20, 18, 10),
        feedMethod: FeedMethod.bottleBreastmilk,
        amountMl: 60,
      ),
      BabyEvent(
        type: EventType.feed,
        occurredAt: DateTime(2026, 2, 20, 17, 30),
        feedMethod: FeedMethod.bottleBreastmilk,
        durationMin: 5,
      ),
      BabyEvent(
        type: EventType.feed,
        occurredAt: DateTime(2026, 2, 20, 15, 50),
        feedMethod: FeedMethod.bottleFormula,
        amountMl: 50,
      ),
    ];

    expect(formatTimelineGroupSummary(events), '喂奶3次 110ml');
  });

  test('formats non-feed same type summary', () {
    final events = [
      BabyEvent(type: EventType.pee, occurredAt: DateTime(2026, 2, 20, 18, 10)),
      BabyEvent(type: EventType.pee, occurredAt: DateTime(2026, 2, 20, 17, 30)),
    ];

    expect(formatTimelineGroupSummary(events), '换尿布 2 次');
  });

  test('extracts event day starts for calendar markers', () {
    final events = [
      BabyEvent(type: EventType.pee, occurredAt: DateTime(2026, 2, 20, 23, 30)),
      BabyEvent(type: EventType.feed, occurredAt: DateTime(2026, 2, 20, 8, 20)),
      BabyEvent(type: EventType.feed, occurredAt: DateTime(2026, 2, 19, 7, 0)),
    ];

    final days = collectEventDayStarts(events);

    expect(days.length, 2);
    expect(days, contains(DateTime(2026, 2, 20)));
    expect(days, contains(DateTime(2026, 2, 19)));
  });
}
