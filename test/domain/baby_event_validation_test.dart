import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed event requires method and amount or duration', () {
    final event = BabyEvent(type: EventType.feed, occurredAt: DateTime.now());

    expect(event.validateForSave, throwsFormatException);
  });

  test('feed event with method and amount is valid', () {
    final event = BabyEvent(
      type: EventType.feed,
      occurredAt: DateTime.now(),
      feedMethod: FeedMethod.bottleFormula,
      amountMl: 90,
    );

    expect(event.validateForSave, returnsNormally);
  });

  test('poop event can be saved without feed fields', () {
    final event = BabyEvent(type: EventType.poop, occurredAt: DateTime.now());

    expect(event.validateForSave, returnsNormally);
  });

  test('pump event requires start, end and amount', () {
    final event = BabyEvent(
      type: EventType.pump,
      occurredAt: DateTime.now(),
      pumpStartAt: DateTime.now(),
      pumpEndAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    expect(event.validateForSave, throwsFormatException);
  });

  test('pump event with valid fields is valid', () {
    final start = DateTime.now();
    final event = BabyEvent(
      type: EventType.pump,
      occurredAt: start,
      pumpStartAt: start,
      pumpEndAt: start.add(const Duration(minutes: 15)),
      amountMl: 120,
    );

    expect(event.validateForSave, returnsNormally);
  });
}
