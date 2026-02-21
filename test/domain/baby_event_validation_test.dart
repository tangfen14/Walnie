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

  test('feed event allows duration 0 when amount is provided', () {
    final event = BabyEvent(
      type: EventType.feed,
      occurredAt: DateTime.now(),
      feedMethod: FeedMethod.bottleBreastmilk,
      durationMin: 0,
      amountMl: 80,
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

  test('pump event side ml must match total amount when provided', () {
    final start = DateTime.now();
    final event = BabyEvent(
      type: EventType.pump,
      occurredAt: start,
      pumpStartAt: start,
      pumpEndAt: start.add(const Duration(minutes: 15)),
      amountMl: 80,
      eventMeta: const EventMeta(
        schemaVersion: 1,
        pumpLeftMl: 30,
        pumpRightMl: 40,
        attachments: [],
      ),
    );

    expect(event.validateForSave, throwsFormatException);
  });

  test('diaper event defaults to mixed status and no rash', () {
    final event = BabyEvent(type: EventType.diaper, occurredAt: DateTime.now());
    final meta = event.eventMeta;

    expect(meta, isNotNull);
    expect(meta!.status, DiaperStatus.mixed);
    expect(meta.changedDiaper, isTrue);
    expect(meta.hasRash, isFalse);
    expect(meta.attachments, isEmpty);
    expect(event.validateForSave, returnsNormally);
  });

  test('legacy poop event defaults to poop status and changed diaper yes', () {
    final event = BabyEvent(type: EventType.poop, occurredAt: DateTime.now());
    final meta = event.eventMeta;

    expect(meta, isNotNull);
    expect(meta!.status, DiaperStatus.poop);
    expect(meta.changedDiaper, isTrue);
    expect(meta.attachments, isEmpty);
    expect(event.validateForSave, returnsNormally);
  });

  test('diaper event requires eventMeta status', () {
    final event = BabyEvent(
      type: EventType.diaper,
      occurredAt: DateTime.now(),
      eventMeta: const EventMeta(schemaVersion: 1, attachments: []),
    );

    expect(event.validateForSave, throwsFormatException);
  });

  test('poop event ignores hasRash and remains valid', () {
    final event = BabyEvent(
      type: EventType.poop,
      occurredAt: DateTime.now(),
      eventMeta: const EventMeta(
        schemaVersion: 1,
        status: DiaperStatus.poop,
        changedDiaper: true,
        hasRash: true,
        attachments: [],
      ),
    );

    expect(event.eventMeta?.hasRash, isNull);
    expect(event.validateForSave, returnsNormally);
  });

  test('diaper event defaults changedDiaper to yes when omitted', () {
    final event = BabyEvent(
      type: EventType.diaper,
      occurredAt: DateTime.now(),
      eventMeta: const EventMeta(
        schemaVersion: 1,
        status: DiaperStatus.pee,
        attachments: [],
      ),
    );

    expect(event.eventMeta?.changedDiaper, isTrue);
    expect(event.validateForSave, returnsNormally);
  });

  test('diaper event rejects more than three attachments', () {
    final event = BabyEvent(
      type: EventType.diaper,
      occurredAt: DateTime.now(),
      eventMeta: EventMeta(
        schemaVersion: 1,
        status: DiaperStatus.mixed,
        changedDiaper: true,
        hasRash: false,
        attachments: const [
          EventAttachment(
            id: '1',
            mimeType: 'image/jpeg',
            base64: 'A',
            createdAt: '2026-02-20T10:00:00.000Z',
          ),
          EventAttachment(
            id: '2',
            mimeType: 'image/jpeg',
            base64: 'B',
            createdAt: '2026-02-20T10:00:00.000Z',
          ),
          EventAttachment(
            id: '3',
            mimeType: 'image/png',
            base64: 'C',
            createdAt: '2026-02-20T10:00:00.000Z',
          ),
          EventAttachment(
            id: '4',
            mimeType: 'image/jpeg',
            base64: 'D',
            createdAt: '2026-02-20T10:00:00.000Z',
          ),
        ],
      ),
    );

    expect(event.validateForSave, throwsFormatException);
  });
}
