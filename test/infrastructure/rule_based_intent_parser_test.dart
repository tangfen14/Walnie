import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/infrastructure/voice/rule_based_intent_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = RuleBasedIntentParser();

  test('parses feeding command with amount and relative time', () {
    final intent = parser.parse('10分钟前喂奶60毫升');

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(intent.payload['amountMl'], 60);
    expect(intent.payload['occurredAt'], isA<String>());
  });

  test('parses reminder command', () {
    final intent = parser.parse('提醒我每3小时喂奶');

    expect(intent.intentType, VoiceIntentType.setReminder);
    expect(intent.payload['intervalHours'], 3);
  });

  test('parses query command', () {
    final intent = parser.parse('今天喂了几次');

    expect(intent.intentType, VoiceIntentType.querySummary);
    expect(intent.payload['query'], contains('今天'));
  });

  test('parses feeding command with HH:mm time', () {
    final intent = parser.parse('3:00喂奶50毫升');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(intent.payload['amountMl'], 50);
    expect(occurredAt.hour, 3);
    expect(occurredAt.minute, 0);
  });

  test('parses feeding command with full-width HH：mm time', () {
    final intent = parser.parse('今天3：20喂奶');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(occurredAt.hour, 3);
    expect(occurredAt.minute, 20);
  });

  test('parses pump command with amount and duration', () {
    final intent = parser.parse('吸奶25分钟120毫升');
    final start = DateTime.parse(intent.payload['pumpStartAt'] as String);
    final end = DateTime.parse(intent.payload['pumpEndAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'pump');
    expect(intent.payload['amountMl'], 120);
    expect(intent.payload['durationMin'], 25);
    expect(end.isAfter(start), isTrue);
  });
}
