import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/today_summary.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';

class GetTodaySummaryUseCase {
  GetTodaySummaryUseCase(this._eventRepository);

  final EventRepository _eventRepository;

  Future<TodaySummary> call() async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final events = await _eventRepository.list(dayStart, dayEnd);

    var feedCount = 0;
    var poopCount = 0;
    var peeCount = 0;
    var diaperCount = 0;
    var pumpCount = 0;
    DateTime? latestFeed;

    for (final event in events) {
      switch (event.type) {
        case EventType.feed:
          feedCount += 1;
          if (latestFeed == null || event.occurredAt.isAfter(latestFeed)) {
            latestFeed = event.occurredAt;
          }
          break;
        case EventType.poop:
          poopCount += 1;
          break;
        case EventType.pee:
          peeCount += 1;
          break;
        case EventType.diaper:
          diaperCount += 1;
          break;
        case EventType.pump:
          pumpCount += 1;
          break;
      }
    }

    return TodaySummary(
      feedCount: feedCount,
      poopCount: poopCount,
      peeCount: peeCount,
      diaperCount: diaperCount,
      pumpCount: pumpCount,
      latestFeedAt: latestFeed,
    );
  }
}
