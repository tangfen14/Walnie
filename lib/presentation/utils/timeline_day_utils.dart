import 'package:baby_tracker/domain/entities/baby_event.dart';

DateTime dayStartOf(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

Set<DateTime> collectEventDayStarts(List<BabyEvent> events) {
  return events.map((event) => dayStartOf(event.occurredAt)).toSet();
}

int totalFeedAmountMl(List<BabyEvent> events) {
  return events
      .where((event) => event.type == EventType.feed)
      .fold<int>(0, (sum, event) => sum + (event.amountMl ?? 0));
}

int totalPumpAmountMl(List<BabyEvent> events) {
  return events
      .where((event) => event.type == EventType.pump)
      .fold<int>(0, (sum, event) => sum + (event.amountMl ?? 0));
}

String formatTimelineGroupSummary(List<BabyEvent> events) {
  final count = events.length;
  if (count == 0) {
    return '无记录';
  }

  final firstType = events.first.type;
  final allSameType = events.every((item) => item.type == firstType);

  if (allSameType && firstType == EventType.feed) {
    final totalMl = totalFeedAmountMl(events);
    return '喂奶$count次 ${totalMl}ml';
  }

  if (allSameType && firstType == EventType.pump) {
    final totalMl = totalPumpAmountMl(events);
    return '吸奶$count次 ${totalMl}ml';
  }

  if (allSameType) {
    final label = firstType == EventType.poop || firstType == EventType.pee
        ? EventType.diaper.labelZh
        : firstType.labelZh;
    return '$label $count 次';
  }

  return '全部记录 $count 条';
}
