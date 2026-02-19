import 'package:baby_tracker/application/usecases/get_today_summary_use_case.dart';
import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryEventRepository implements EventRepository {
  _MemoryEventRepository(this.items);

  final List<BabyEvent> items;

  @override
  Future<void> create(BabyEvent event) async {
    items.add(event);
  }

  @override
  Future<BabyEvent?> latest(EventType type) async {
    for (var i = items.length - 1; i >= 0; i--) {
      if (items[i].type == type) {
        return items[i];
      }
    }
    return null;
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    return items
        .where(
          (event) =>
              !event.occurredAt.isBefore(from) && event.occurredAt.isBefore(to),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteById(String id) async {
    items.removeWhere((event) => event.id == id);
  }
}

void main() {
  test('counts today summary correctly', () async {
    final now = DateTime.now();
    final repo = _MemoryEventRepository([
      BabyEvent(
        type: EventType.feed,
        occurredAt: now.subtract(const Duration(hours: 1)),
        feedMethod: FeedMethod.bottleFormula,
        amountMl: 80,
      ),
      BabyEvent(
        type: EventType.pee,
        occurredAt: now.subtract(const Duration(minutes: 30)),
      ),
      BabyEvent(
        type: EventType.poop,
        occurredAt: now.subtract(const Duration(minutes: 20)),
      ),
      BabyEvent(
        type: EventType.feed,
        occurredAt: now.subtract(const Duration(minutes: 10)),
        feedMethod: FeedMethod.bottleBreastmilk,
        amountMl: 60,
      ),
      BabyEvent(
        type: EventType.pump,
        occurredAt: now.subtract(const Duration(minutes: 5)),
        pumpStartAt: now.subtract(const Duration(minutes: 25)),
        pumpEndAt: now.subtract(const Duration(minutes: 5)),
        amountMl: 100,
      ),
    ]);

    final useCase = GetTodaySummaryUseCase(repo);
    final summary = await useCase();

    expect(summary.feedCount, 2);
    expect(summary.pumpCount, 1);
    expect(summary.peeCount, 1);
    expect(summary.poopCount, 1);
    expect(summary.latestFeedAt, isNotNull);
  });
}
